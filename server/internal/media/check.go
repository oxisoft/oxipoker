package media

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/url"
	"strconv"
	"strings"
	"time"
)

// Result states of one connection check.
const (
	CheckOK      = "ok"
	CheckFailed  = "failed"
	CheckSkipped = "skipped"
)

// CheckResult is one line of the admin console's connection check: what was
// tried, how it went, and for a failure what to change.
type CheckResult struct {
	Name   string `json:"name"`   // signalling, token, turn_tls
	Status string `json:"status"` // ok, failed, skipped
	Target string `json:"target"` // the address that was tried
	Detail string `json:"detail"` // plain explanation (always set)
}

// Report is the body of GET /api/v1/admin/media-check.
type Report struct {
	Enabled bool          `json:"enabled"`
	Checks  []CheckResult `json:"checks"`
}

// Checker runs the connection check from the server's side.
type Checker struct {
	Config  Config
	Client  *http.Client                                                  // nil = 5 s timeout
	DialTLS func(ctx context.Context, addr string, cfg *tls.Config) error // nil = real dial
	Now     func() time.Time
}

const checkTimeout = 5 * time.Second

// Run checks, in order: LiveKit answers at LIVEKIT_URL (signalling), a token
// signed with this server's key is accepted there (round trip), and the TURN
// TLS port answers with a valid certificate. A later check is skipped when
// an earlier one it depends on failed.
func (c Checker) Run(ctx context.Context) Report {
	cfg := c.Config
	if !cfg.Enabled() {
		return Report{Enabled: false, Checks: []CheckResult{{Name: "signalling", Status: CheckSkipped,
			Detail: "Voice and video are off: LIVEKIT_URL, LIVEKIT_API_KEY and LIVEKIT_API_SECRET are not set. Set all three and start LiveKit with docker compose --profile full up -d to turn calls on."}}}
	}
	client := c.Client
	if client == nil {
		client = &http.Client{Timeout: checkTimeout}
	}
	now := time.Now
	if c.Now != nil {
		now = c.Now
	}
	base := httpBase(cfg.URL)
	rep := Report{Enabled: true}

	sig := CheckResult{Name: "signalling", Target: cfg.URL}
	code, body, err := get(ctx, client, base+"/")
	switch {
	case err != nil:
		sig.Status, sig.Detail = CheckFailed, explainNetErr(err, "LIVEKIT_URL", "Check that the name resolves to this box, that the reverse proxy forwards it to LiveKit (LIVEKIT_HTTP_PORT) and that the livekit container runs (docker compose ps).")
	case code == http.StatusNotAcceptable && strings.HasPrefix(strings.TrimSpace(body), "Not Ready"):
		// LiveKit's health answer while its node stats are stale: the first
		// seconds after start, or a box too busy to update them.
		sig.Status = CheckFailed
		sig.Detail = "LiveKit answers at LIVEKIT_URL but says it is not ready yet. That is normal for a few seconds after it starts; run the check again in a minute. If it stays, the box is overloaded or LiveKit is stuck: see docker compose logs livekit."
	case code != http.StatusOK || strings.TrimSpace(body) != "OK":
		sig.Status = CheckFailed
		sig.Detail = fmt.Sprintf("Something answers at LIVEKIT_URL, but it is not LiveKit (HTTP %d). The reverse proxy probably sends this name to another service: forward it to LiveKit (LIVEKIT_HTTP_PORT) with WebSocket upgrade.", code)
	default:
		sig.Status, sig.Detail = CheckOK, "LiveKit answers at LIVEKIT_URL."
	}
	rep.Checks = append(rep.Checks, sig)

	tok := CheckResult{Name: "token", Target: cfg.URL}
	if sig.Status != CheckOK {
		tok.Status, tok.Detail = CheckSkipped, "Skipped: LiveKit is not reachable."
	} else {
		t, _, err := cfg.JoinToken("connection-check", "connection-check", "Connection check", now())
		if err != nil {
			tok.Status, tok.Detail = CheckFailed, "The server could not sign a call token: "+err.Error()
		} else {
			code, body, err := get(ctx, client, base+"/rtc/validate?access_token="+url.QueryEscape(t))
			switch {
			case err != nil:
				tok.Status, tok.Detail = CheckFailed, explainNetErr(err, "LIVEKIT_URL", "LiveKit answered a moment ago; check its logs (docker compose logs livekit).")
			case code == http.StatusOK:
				tok.Status, tok.Detail = CheckOK, "LiveKit accepts the call tokens this server signs."
			case code == http.StatusUnauthorized:
				tok.Status = CheckFailed
				tok.Detail = "LiveKit refused a token signed by this server: LIVEKIT_API_KEY and LIVEKIT_API_SECRET differ from the keys LiveKit was started with. Use the same pair for both services and restart them (docker compose up -d)."
				if strings.Contains(body, "expired") || strings.Contains(body, "not valid yet") {
					tok.Detail = "LiveKit refused a token as expired or not yet valid: the clocks of this server and LiveKit differ. Turn on time sync (NTP) on the box."
				}
			default:
				tok.Status = CheckFailed
				tok.Detail = fmt.Sprintf("LiveKit answered the token check with HTTP %d. The reverse proxy may block the /rtc path: forward every path of this name to LiveKit.", code)
			}
		}
	}
	rep.Checks = append(rep.Checks, tok)

	turn := CheckResult{Name: "turn_tls"}
	if cfg.TURNDomain == "" || cfg.TURNTLSPort == 0 {
		turn.Status = CheckSkipped
		turn.Detail = "TURN is off (LIVEKIT_TURN_ENABLED, LIVEKIT_TURN_DOMAIN). Calls work for most players; those whose network blocks UDP (some offices, hotels, mobile carriers) cannot join until TURN over TLS is set up."
	} else {
		addr := net.JoinHostPort(cfg.TURNDomain, strconv.Itoa(cfg.TURNTLSPort))
		turn.Target = addr
		dial := c.DialTLS
		if dial == nil {
			dial = dialTLS
		}
		dctx, cancel := context.WithTimeout(ctx, checkTimeout)
		err := dial(dctx, addr, &tls.Config{ServerName: cfg.TURNDomain, MinVersion: tls.VersionTLS12})
		cancel()
		var certErr *tls.CertificateVerificationError
		var hostErr x509.HostnameError
		switch {
		case err == nil:
			turn.Status, turn.Detail = CheckOK, "The TURN TLS port answers with a valid certificate for LIVEKIT_TURN_DOMAIN."
		case errors.As(err, &hostErr):
			turn.Status, turn.Detail = CheckFailed, "The TURN TLS port answers, but its certificate is for another name. Put the certificate of LIVEKIT_TURN_DOMAIN into LIVEKIT_TURN_CERT_DIR and restart livekit."
		case errors.As(err, &certErr):
			turn.Status, turn.Detail = CheckFailed, "The TURN TLS port answers, but its certificate is not valid (expired, self-signed or missing the chain). Use fullchain.pem from your certificate tool and restart livekit after every renewal."
		default:
			turn.Status, turn.Detail = CheckFailed, explainNetErr(err, "LIVEKIT_TURN_DOMAIN", "Open LIVEKIT_TURN_TLS_PORT/tcp in the firewall, check LIVEKIT_TURN_ENABLED=true and that nothing else (a web server) holds that port.")
		}
	}
	rep.Checks = append(rep.Checks, turn)
	return rep
}

func httpBase(raw string) string {
	u, err := url.Parse(raw)
	if err != nil {
		return raw
	}
	switch u.Scheme {
	case "ws":
		u.Scheme = "http"
	case "wss":
		u.Scheme = "https"
	}
	return strings.TrimRight(u.String(), "/")
}

func get(ctx context.Context, client *http.Client, u string) (int, string, error) {
	ctx, cancel := context.WithTimeout(ctx, checkTimeout)
	defer cancel()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, u, nil)
	if err != nil {
		return 0, "", err
	}
	res, err := client.Do(req)
	if err != nil {
		return 0, "", err
	}
	defer res.Body.Close()
	b, _ := io.ReadAll(io.LimitReader(res.Body, 4<<10))
	return res.StatusCode, string(b), nil
}

func dialTLS(ctx context.Context, addr string, cfg *tls.Config) error {
	d := tls.Dialer{Config: cfg}
	conn, err := d.DialContext(ctx, "tcp", addr)
	if err != nil {
		return err
	}
	return conn.Close()
}

// explainNetErr turns a dial or request error into a sentence for an admin.
func explainNetErr(err error, setting, otherwise string) string {
	var dnsErr *net.DNSError
	var certErr *tls.CertificateVerificationError
	var hostErr x509.HostnameError
	var opErr *net.OpError
	switch {
	case errors.As(err, &dnsErr):
		return "The name in " + setting + " does not resolve. Create its DNS record (A or AAAA) pointing to this box."
	case errors.As(err, &hostErr), errors.As(err, &certErr):
		return "The HTTPS certificate for " + setting + " is not valid for that name. Get a certificate for it in the reverse proxy."
	case errors.Is(err, context.DeadlineExceeded) || isTimeout(err):
		return "No answer within 5 seconds from " + setting + ": a firewall probably drops the connection. " + otherwise
	case errors.As(err, &opErr) && opErr.Op == "dial":
		return "Nothing accepts connections at " + setting + " (connection refused). " + otherwise
	default:
		return "Could not reach " + setting + ": " + err.Error() + ". " + otherwise
	}
}

func isTimeout(err error) bool {
	var ne net.Error
	return errors.As(err, &ne) && ne.Timeout()
}
