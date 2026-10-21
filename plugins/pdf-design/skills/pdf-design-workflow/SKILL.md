---
name: pdf-design-workflow
author: Danilo-enesi
description: Entry point for understanding a design delivered as PDF (mockup, newsletter, landing page, brochure) so it can be built or handed to another agent. Use when the user gives a design PDF and says "understand/analyze this design", "prepare it for the builder", "replicate this PDF". Only gives the order of the pdf-design skills; each step is its own skill.
---

# pdf-design-workflow

**Rule:** one skill per step, scripts do the work, you never read the PDF into context.

## Order

| # | Skill | Produces |
|---|---|---|
| 1 | `pdf-design-tools` | tools checked/installed (never root, never global) |
| 2 | `pdf-design-extract` | `design/` with pages, text, shapes, assets, svg |
| 3 | `pdf-design-fonts` | `fonts.json`: real or deduced font names |
| 4 | `pdf-design-tokens` | `tokens.json`: palette, type scale, spacing, px scale |
| 5 | `pdf-design-sections` | `sections/*.png` + `sections.json` |
| 6 | `pdf-design-brief` | `interpretation.json` (your judgement) + `DESIGN.md` for an AI builder |
| 7 | `pdf-design-recreate` | `preview.html`: the design in HTML, for the user, verified with `html-visual-diff` |

Steps 1–5 are mechanical: run them in a row. Step 6 is where you look at the page once and think. Step 7 only if the user wants to see the design in HTML.

Two audiences: the user opens only `preview.html`; an AI builder reads `DESIGN.md` + `tokens.json` and opens `sections/*.png` one at a time.

## Shared rules

- Work folder: `design/` next to where the user works, unless they say otherwise. Never write into a folder you did not create.
- Run Python with `-I`; print only counts, write everything else to files.
- Assets in SVG -> `svg-to-png` (with `--dark` when the target supports dark mode).
- When a step fails, fix that step's skill only and re-run from that step.
