// Package version holds the release version, set at build time with
// -ldflags "-X github.com/oxisoft/oxipoker/server/internal/version.Version=1.2.3".
package version

// Version is "dev" for local builds and the tag without the leading v for releases.
var Version = "dev"

// API is the level of the HTTP and WebSocket API this server speaks. It grows
// when a change needs a newer server; apps compare it with the level they need
// and tell the player when the server is too old. 1 = Oxi Poker 1.0.
const API = 1
