---
name: pdf-design-tokens
author: Danilo-enesi
description: Build design tokens (color palette by frequency, fonts and weights, type scale, frequent spacings, content container and the pt-to-px scale) from a folder produced by pdf-design-extract. Use after extraction when you need "the palette", "the type scale", "the tokens" or the real px sizes of a PDF mockup. Only computes tokens; it does not assign meaning to colors.
---

# pdf-design-tokens

**Rule:** a PDF is in points, the build is in px. Get the scale right first, everything else follows.

## Steps

1. Decide the real width of the content column. Look at `design/pages/page-1.png` once:
   - email -> usually 600 px; website -> ask, or use the grid width (e.g. 1200).
   - unsure -> run without `--target-width` (1pt = 1.333px) and ask the user.
2. Run it (`scripts/` is relative to this skill's directory):
   ```
   python -I scripts/tokens.py --out design --target-width 600
   ```
3. Check the printed container. Auto-detection takes the widest image, else the widest shape narrower than the page. If it is wrong (e.g. it took a page wrapper), pass `--container x0,x1` in pt.
4. Sanity check: the px font sizes should be round-ish numbers (11, 14, 16, 32). If they are all fractional, the target width is probably wrong.

## Output: `design/tokens.json`

- `px_per_pt`, `container` (`bbox_pt`, `width_px`, `source`)
- `colors`: up to 12, by frequency, with `as` = text / fill / stroke
- `fonts`: pdf name, `family` (from `fonts.json` if `pdf-design-fonts` ran first), weight, italic, uses
- `font_sizes`: pt + px + uses; `spacing`: vertical gaps between text blocks, pt + px + uses

## Notes

- Color roles (accent, background, text…) need judgement: they go in `interpretation.json` (see `pdf-design-brief`), not here.
- Next: `pdf-design-sections` (it reads the container from `tokens.json`).
