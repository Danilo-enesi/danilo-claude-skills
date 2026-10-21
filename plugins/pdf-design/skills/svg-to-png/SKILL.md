---
name: svg-to-png
author: Danilo-enesi
description: Convert SVG assets (icons, logos) to PNG with transparent background using a library, plus an automatic dark-mode variant (<name>.dark.png). Use whenever a design or project has .svg assets that must become PNG (emails, Outlook, places without SVG support) or need a dark-mode version. Never redraw or hand-convert SVGs: run the script.
---

# svg-to-png

**Rule:** converting SVG is a library job, not a token job. Never read the SVG source to redraw it.

## Steps

1. Run it on files or folders (`scripts/` is relative to this skill's directory):
   ```
   python -I scripts/svg2png.py design/assets/icons --out design/assets/png --scale 2 --dark
   ```
   - `--scale 2`: twice the SVG's own size (retina). `--width 48`: exact width in px instead.
   - `--dark`: also writes `<name>.dark.png`.
2. Check one light and one dark result visually (open the PNG). A `FAILED` line names the file and the error.
3. Without `--out`, PNGs are written next to each SVG. Existing PNGs with the same name are overwritten: if that folder holds hand-made PNGs, use `--out`.

## How the dark variant works

- Every color (`#rgb`, `#rrggbb`, `rgb()`, basic names) gets its **lightness inverted**, hue and saturation kept: black <-> white, dark grey <-> light grey, mid-tone brand colors barely move.
- Shapes with no fill (default black) and `currentColor` become white.
- It is a good automatic default, not art direction. If a logo has an official dark version, use that instead.

## Notes

- Rendering uses PyMuPDF (MuPDF's SVG engine): no Cairo, no Inkscape, no browser.
- Not supported by MuPDF: CSS animations, some filters, external fonts in `<text>` (convert text to paths in the SVG first).
