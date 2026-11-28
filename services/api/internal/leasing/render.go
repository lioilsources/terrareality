package leasing

import (
	"context"
	"embed"

	"github.com/lioilsources/ol1n_platform_kit/typstdoc"
)

// Templates are copied from packages/attributes/templates by `make gen`.
//
//go:embed templates/cz/*.typ
var templateFS embed.FS

// TemplateVersion identifies the template set; bump it when texts change.
const TemplateVersion = "cz-2026-10-draft"

// Templates available for leases.
var Templates = []string{"byt_doba_urcita", "byt_doba_neurcita", "spolecny_najem", "pokoj"}

// Renderer turns a template and data into a PDF.
type Renderer interface {
	Render(ctx context.Context, template string, data any) ([]byte, error)
}

// ErrNoTypst means the typst binary is missing.
var ErrNoTypst = typstdoc.ErrNoTypst

// Typst renders with the typst CLI using only its embedded fonts, so the
// output does not depend on the fonts of the machine.
type Typst struct {
	Bin string // path or name of the typst binary
}

// Render implements Renderer.
func (t Typst) Render(ctx context.Context, template string, data any) ([]byte, error) {
	return typstdoc.Renderer{FS: templateFS, Dir: "templates/cz", Bin: t.Bin}.Render(ctx, template, data)
}
