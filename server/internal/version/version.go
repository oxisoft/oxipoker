// Package version holds the release version, set at build time with
// -ldflags "-X github.com/oxisoft/oxipoker/server/internal/version.Version=1.2.3".
package version

// Version is "dev" for local builds and the tag without the leading v for releases.
var Version = "dev"
