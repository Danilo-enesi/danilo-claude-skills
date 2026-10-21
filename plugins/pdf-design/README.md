# pdf-design

Claude Code plugin to understand a design delivered as PDF, step by step, so it can be rebuilt or handed to another agent.

One task per skill, scripts for everything that can be automated, nothing read into context that a script can read instead.

## Skills

| Skill | Task | Script |
|---|---|---|
| `pdf-design-workflow` | order of the steps (entry point) | — |
| `pdf-design-tools` | check / install tools (venv or `--user`, never root) | `check_tools.py` |
| `pdf-design-extract` | pages, text with styles, shapes, images, SVG | `extract.py` |
| `pdf-design-fonts` | font names: metadata first (also copyright notices), metrics fingerprint as fallback | `fonts.py` |
| `pdf-design-tokens` | palette, fonts, type scale, spacing, container, pt→px | `tokens.py` |
| `pdf-design-sections` | split pages into sections, crop PNGs | `sections.py` |
| `pdf-design-brief` | `DESIGN.md` for an AI builder (≤100 lines) | `brief.py` |
| `pdf-design-recreate` | `preview.html`: the design in HTML for the user, verified per section | — |
| `svg-to-png` | SVG → PNG + dark-mode variant | `svg2png.py` |
| `html-visual-diff` | headless screenshot + pixel diff % + heatmap | `screenshot.py`, `diff.py` |

## Requirements

Python 3.9+, PyMuPDF, Pillow, Edge or Chrome (only for `html-visual-diff`). No Poppler, Cairo, Playwright or Node.

## Work folder

```
design/
├── info.json  tokens.json  fonts.json  images.json  sections.json
├── interpretation.json      ← the only file written by judgement (feeds DESIGN.md)
├── pages/  text/  shapes/  assets/  svg/  sections/
├── DESIGN.md                ← for an AI builder
├── preview.html             ← for the user: the design in HTML
```

## Install

```
/plugin install pdf-design --marketplace Danilo-enesi/danilo-claude-skills
```
