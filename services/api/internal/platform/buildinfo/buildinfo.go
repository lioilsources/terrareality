// Package buildinfo exposes values injected at link time via -ldflags.
package buildinfo

var (
	Version = "dev"
	Commit  = "none"
	BuiltAt = "unknown"
)
