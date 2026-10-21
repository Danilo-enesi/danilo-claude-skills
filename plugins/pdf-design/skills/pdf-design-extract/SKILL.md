---
name: pdf-design-extract
author: Danilo-enesi
description: Extract the raw data of a design PDF into a work folder - page sizes, PNG renders, text with styles, vector shapes, embedded images (with transparency) and per-page SVG. Use when you get a design/mockup as PDF and need its data without reading the PDF into context ("extract this PDF", "get the assets out of this design"). Only extracts; tokens, fonts, sections and docs are other pdf-design skills.
---

# pdf-design-extract

**Rule:** the script reads the PDF, you read only the counts. Never paste the PDF, JSON or SVG into the conversation.

## Steps

1. Run it (`scripts/` is relative to this skill's directory):
   ```
   python -I scripts/extract.py <file.pdf> --out design
   ```
2. Check the printed counts. Zero text blocks usually means the text was outlined (converted to curves): note it, the text must be typed by hand later.
3. To redo a single step after a fix: `--only text` (steps: `info,pages,text,shapes,images,svg`).
4. If it refuses because the folder is not empty, pick a new `--out`. Use `--force` only if the user confirms that folder may be overwritten.

## Output (`design/`)

| File | Content |
|---|---|
| `info.json` | source path, dpi, page sizes in pt |
| `pages/page-N.png` | page render at `--dpi` (default 150) |
| `text/page-N.json` | blocks -> spans: text, font, size (pt), bold, italic, color hex, bbox |
| `shapes/page-N.json` | vector shapes: type, bbox, fill, stroke, width |
| `assets/` + `images.json` | embedded images at original resolution (soft masks recombined into PNG alpha) and where each one is placed |
| `svg/page-N.svg` | full vector export of each page (do not open it: it is huge) |

## Notes

- bbox values are PDF points `[x0, y0, x1, y1]`, origin top-left.
- Font names may be anonymized (`font0000…`, `AAAAAB+…`): that is the job of `pdf-design-fonts`.
- Next: `pdf-design-fonts`, then `pdf-design-tokens`.
