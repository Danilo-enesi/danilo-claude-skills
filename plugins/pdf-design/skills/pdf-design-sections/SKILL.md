---
name: pdf-design-sections
author: Danilo-enesi
description: Split the pages of a design PDF into horizontal sections (header, hero, content blocks, footer) using the vertical gaps between elements, and crop each one to PNG at the content-column width. Use after pdf-design-extract and pdf-design-tokens when you need per-section images to build or review one section at a time. Only splits and crops.
---

# pdf-design-sections

**Rule:** a builder opens one section PNG at a time, never the whole page.

## Steps

1. Run it (`scripts/` is relative to this skill's directory):
   ```
   python -I scripts/sections.py --out design
   ```
2. Look at `design/pages/page-1.png` once and compare with the printed list:
   - Too many sections (a paragraph split from its title) -> raise `--gap` (e.g. 10).
   - Too few (header glued to hero) -> lower `--gap` (e.g. 4).
   - Each crop the full page width -> the container is wrong: fix it in `pdf-design-tokens`.
3. Re-run until the cuts match the visual blocks. Two or three tries is normal; then accept small imperfections and note them.

## Output

- `design/sections/page-N-sK.png`: crops at the extraction dpi, container width.
- `design/sections.json`: `{page: [{file, bbox}]}`, bbox in pt.

## How it decides

- Elements = text blocks + shapes narrower than 95% of the container (wider ones are backgrounds) + placed images.
- A vertical gap >= `--gap` pt starts a new section; a section thinner than `--divider` pt (a rule line) is glued to the next.
- Elements stacked with no gap (logo bar touching a hero) stay together: that is a limit of the gap method.
- Next: `pdf-design-brief`.
