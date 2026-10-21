---
name: html-visual-diff
author: Danilo-enesi
description: Screenshot an HTML page with headless Edge/Chrome and measure its pixel difference (%) against a reference image, with a red heatmap of what differs. Use to verify that a built page or section matches a design ("compare with the mockup", "check the diff", "is it pixel-perfect?"), in a fix-and-repeat loop. Only measures; it never edits the HTML.
---

# html-visual-diff

**Rule:** a number and a heatmap, not an opinion. Iterate on what the heatmap shows.

## Steps

1. Screenshot the page alone at its real width (no wrappers, toolbars or side-by-side views):
   ```
   python -I scripts/screenshot.py page.html shot.png --width 600
   ```
   (`scripts/` is relative to this skill's directory.)
2. Diff one section. `--find` locates it in the screenshot by itself; never guess coordinates:
   ```
   python -I scripts/diff.py shot.png design/sections/page-1-s3.png --find --heatmap diff-s3.png
   ```
   If the reference must be scaled to a width other than the screenshot's, add `--ref-width <px>`.
   `--crop x,y,w,h` exists for the rare case where `--find` matches the wrong place (repeated blocks).
3. If diff > 2%: open the heatmap, fix the biggest red area in the HTML, repeat. Max 3 iterations per section.
4. Report only: section, diff %, what you adjusted. If it stays above 2% after 3 tries, report the cause (usually the font).

## Reading the result

- Red text everywhere but layout aligned -> font fallback (e.g. no Helvetica Neue on Windows). Not fixable in CSS; report it.
- Red band shifting everything below -> a height/margin is off above that band: fix that first.
- `heights differ` -> the section is taller/shorter: compare paddings before details.

## Notes

- Uses a throwaway browser profile: never touches the user's browser data.
- Needs Pillow and Edge/Chrome: if missing, run `pdf-design-tools`.
- `--threshold` (default 32) ignores antialiasing noise; lower it for strict comparisons.
