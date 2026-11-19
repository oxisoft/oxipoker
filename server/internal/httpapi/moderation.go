package httpapi

import (
	"errors"
	"net/http"
	"strconv"

	"github.com/go-chi/chi/v5"

	"github.com/oxisoft/oxipoker/server/internal/accounts"
)

func (g *gameAPI) moderationRoutes(r chi.Router) {
	r.Get("/me/blocks", g.listBlocks)
	r.Put("/me/blocks/{id}", g.block)
	r.Delete("/me/blocks/{id}", g.unblock)
	r.Post("/reports", g.report)
	r.Group(func(r chi.Router) {
		r.Use(requireAdmin)
		r.Get("/admin/reports", g.listReports)
		r.Post("/admin/reports/{id}/resolve", g.resolveReport)
	})
}

func (g *gameAPI) listBlocks(w http.ResponseWriter, r *http.Request) {
	bs, err := g.acc.Blocks(r.Context(), currentUser(r).ID)
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"blocks": bs})
}

// pushBlocks hands the fresh block list to the user's open connections, so
// a block hides chat at once.
func (g *gameAPI) pushBlocks(r *http.Request, user string) {
	if set, err := g.acc.BlockedIDs(r.Context(), user); err == nil {
		g.hub.SetBlocks(user, set)
	}
}

func (g *gameAPI) block(w http.ResponseWriter, r *http.Request) {
	u := currentUser(r)
	err := g.acc.Block(r.Context(), u.ID, chi.URLParam(r, "id"))
	switch {
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
	case errors.Is(err, accounts.ErrBlockSelf):
		writeError(w, http.StatusBadRequest, "block_self")
	case errors.Is(err, accounts.ErrTooManyBlocks):
		writeError(w, http.StatusConflict, "too_many_blocks")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		g.pushBlocks(r, u.ID)
		w.WriteHeader(http.StatusNoContent)
	}
}

func (g *gameAPI) unblock(w http.ResponseWriter, r *http.Request) {
	u := currentUser(r)
	if err := g.acc.Unblock(r.Context(), u.ID, chi.URLParam(r, "id")); err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	g.pushBlocks(r, u.ID)
	w.WriteHeader(http.StatusNoContent)
}

// report files a report. With a table the server adds that table's last
// chat lines itself; the reporter cannot supply or edit them.
func (g *gameAPI) report(w http.ResponseWriter, r *http.Request) {
	var req struct {
		User   string `json:"user"`
		Table  string `json:"table"`
		Reason string `json:"reason"`
		Note   string `json:"note"`
	}
	if !readJSON(w, r, &req, 8<<10) {
		return
	}
	u := currentUser(r)
	n := accounts.NewReport{Reporter: u.ID, Reported: req.User, Reason: req.Reason, Note: req.Note}
	if req.Table != "" {
		if st, ok := g.hub.State(req.Table); ok {
			n.TableID, n.TableName = st.ID, st.Settings.Name
			for _, l := range g.hub.RecentChat(st.ID) {
				n.Chat = append(n.Chat, accounts.ChatLine{User: l.User, Name: l.Name, Text: l.Text, At: l.At})
			}
		}
	}
	rep, err := g.acc.FileReport(r.Context(), n)
	switch {
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
	case errors.Is(err, accounts.ErrBadReport):
		writeError(w, http.StatusBadRequest, "bad_report")
	case errors.Is(err, accounts.ErrReportSelf):
		writeError(w, http.StatusBadRequest, "report_self")
	case errors.Is(err, accounts.ErrTooManyReports):
		writeError(w, http.StatusTooManyRequests, "too_many_reports")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		g.audit(r, u, "report.file", rep.ReportedID, map[string]any{"report": rep.ID, "reason": rep.Reason})
		writeJSON(w, http.StatusCreated, map[string]any{"id": rep.ID})
	}
}

func (g *gameAPI) listReports(w http.ResponseWriter, r *http.Request) {
	rs, err := g.acc.Reports(r.Context(), r.URL.Query().Get("all") == "1", queryInt(r, "limit"))
	if err != nil {
		writeError(w, http.StatusInternalServerError, "internal")
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"reports": rs})
}

func (g *gameAPI) resolveReport(w http.ResponseWriter, r *http.Request) {
	id, err := strconv.ParseInt(chi.URLParam(r, "id"), 10, 64)
	if err != nil {
		writeError(w, http.StatusNotFound, "not_found")
		return
	}
	u := currentUser(r)
	err = g.acc.ResolveReport(r.Context(), id, u.Username)
	switch {
	case errors.Is(err, accounts.ErrNotFound):
		writeError(w, http.StatusNotFound, "not_found")
	case err != nil:
		writeError(w, http.StatusInternalServerError, "internal")
	default:
		g.audit(r, u, "report.resolve", strconv.FormatInt(id, 10), nil)
		w.WriteHeader(http.StatusNoContent)
	}
}
