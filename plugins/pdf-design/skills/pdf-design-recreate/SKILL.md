---
name: pdf-design-recreate
author: Danilo-enesi
description: Recreate a design PDF as a static HTML page, design/preview.html - the one file the user opens to see the design - from the extracted data, section by section, verifying each section with html-visual-diff. Use when the user wants to "see the design in HTML", "rebuild the mockup", or needs a pixel-checked reference before porting it into a real template. Builds a standalone page only, not the project's template.
---

# pdf-design-recreate

**Rule:** build from the data, check against the pixels. Never estimate a size the JSON already gives you.

## Steps

1. Read `design/DESIGN.md` and `design/tokens.json` (run `pdf-design-brief` first if missing).
2. Create `design/preview.html`: one file, no frameworks, no external files, relative paths (`assets/…`), opens by double-click.
   - Body width = `tokens.container.width_px`. Every size: `px = pt × px_per_pt`.
   - Text, font sizes, colors: copy from `text/page-N.json` (search by text, don't read it whole).
   - Images: `assets/` files placed at their `images.json` bbox; SVG icons -> `svg-to-png` if the target needs PNG.
   - Fonts: the stacks from `interpretation.json`.
   - Email target -> tables + inline styles; web target -> semantic HTML + one `<style>`.
3. Build one section at a time, opening only that section's PNG.
4. Verify each section with `html-visual-diff` (`--find`). Target <= 2%, max 3 fixes per section.
5. Report per section: diff %, what you adjusted, what remains (usually font fallback). Give the user the path to `preview.html`.

## Notes

- Keep the page clean (no toolbars, no side-by-side views): it is both what the user sees and what the diff measures.
- Placeholders in the PDF (grey boxes "400 × 280") stay placeholders: list them as pending.
- If text was outlined in the PDF (no text in `text/`), type it from the section PNG and say so.
