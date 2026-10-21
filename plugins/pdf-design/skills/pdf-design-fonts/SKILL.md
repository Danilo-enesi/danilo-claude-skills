---
name: pdf-design-fonts
author: Danilo-enesi
description: Identify the fonts used in a PDF, including anonymized ones (names like font00000000306569ce or AAAAAB+...). Reads metadata first (embedded font name table, PDF font dictionaries, copyright/trademark notices); only if no metadata answers, falls back to a metrics fingerprint (x-height, cap-height, OS/2 vendor). Never identifies fonts by looking at glyphs. Use for "which fonts does this PDF use?", "recognize the fonts from the metadata", or when extracted text shows meaningless font names. Only identifies fonts.
---

# pdf-design-fonts

**Rule:** metadata first, fingerprint second, never by eye. Comparing glyphs visually is not reliable: don't do it, don't suggest it.

## Steps

1. Run it (`scripts/` is relative to this skill's directory):
   ```
   python -I scripts/fonts.py <file.pdf> --out design
   ```
2. Read the printed lines. Each has a `confidence` and the `source` that decided it:
   - `metadata`: a real name was found (font name table, PDF `/FontFamily` / `/BaseFont`, or a copyright notice that names or signs the family). Report as identified.
   - `fingerprint+vendor`: no metadata; x-height + cap-height and the OS/2 vendor match a known font. Report as **deduced**, list the other `candidates`.
   - `fingerprint`: only the metrics match. Report as **plausible**, with all candidates.
   - `unknown`: nothing matched. Report the printed fingerprint (vendor, x-height, cap-height) and the `notice:` line, and ask the user. Do not guess.
3. Tell the user the confidence for each font in plain words (identified / deduced / unknown).

## Output

`design/fonts.json`: one entry per distinct font/style with `pdf_name`, `style`, `weight`, `identified_as`, `confidence`, `source`, `candidates`, `vendor` (e.g. `LINO` Linotype, `TMC` Monotype, `GOOG` Google), `x_height`, `cap_height` (per 1000 em), `metadata` (every name/notice string found), `subsets`.

## Extending it (no other change needed)

- New notice signature -> `NOTICES` in `scripts/fonts.py`: a substring of the copyright notice, taken from a font file you actually inspected.
- New metrics reference -> `KNOWN`: `(x_height, cap_height, vendor)` per 1000 em, from the font's own OS/2 or AFM data.

## Notes

- PDFs printed from macOS, Google Docs or Skia rename fonts to `font0000…`, but the copyright notice inside the font file often survives: that is why notices are read.
- Non web-safe results (Helvetica Neue, licensed fonts) matter for HTML: the brief flags them.
