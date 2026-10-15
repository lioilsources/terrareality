package leasing

import (
	"context"
	"embed"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"
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
var ErrNoTypst = errors.New("typst binary not found")

// Typst renders with the typst CLI using only its embedded fonts, so the
// output does not depend on the fonts of the machine.
type Typst struct {
	Bin string // path or name of the typst binary
}

// Render implements Renderer.
func (t Typst) Render(ctx context.Context, template string, data any) ([]byte, error) {
	bin := t.Bin
	if bin == "" {
		bin = "typst"
	}
	if _, err := exec.LookPath(bin); err != nil {
		return nil, ErrNoTypst
	}
	dir, err := os.MkdirTemp("", "terra-lease-")
	if err != nil {
		return nil, err
	}
	defer os.RemoveAll(dir)
	entries, err := templateFS.ReadDir("templates/cz")
	if err != nil {
		return nil, err
	}
	for _, e := range entries {
		b, _ := templateFS.ReadFile("templates/cz/" + e.Name())
		if err := os.WriteFile(filepath.Join(dir, e.Name()), b, 0o600); err != nil {
			return nil, err
		}
	}
	if _, err := templateFS.ReadFile("templates/cz/" + template + ".typ"); err != nil {
		return nil, fmt.Errorf("unknown template %q", template)
	}
	raw, err := json.Marshal(data)
	if err != nil {
		return nil, err
	}
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	out := filepath.Join(dir, "out.pdf")
	cmd := exec.CommandContext(ctx, bin, "compile", "--ignore-system-fonts", "--root", dir,
		"--input", "data="+string(raw), filepath.Join(dir, template+".typ"), out)
	if msg, err := cmd.CombinedOutput(); err != nil {
		return nil, fmt.Errorf("typst: %v: %.500s", err, msg)
	}
	return os.ReadFile(out)
}
