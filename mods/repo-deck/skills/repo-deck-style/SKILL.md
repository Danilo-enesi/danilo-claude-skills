---
name: repo-deck-style
author: Danilo-enesi
description: The design rules of the repo-deck pane, derived from the "Flightdeck" reference analysis - one accent colour per kind, mono grid, `·` separators, collapsible bordered cards, what is hidden when empty, button labels. Use before any visual change to repo-deck (colours, cards, rows, header, summary, buttons) or when asked "how should this look" / "is this consistent". Only states the rules; editing is repo-deck-edit-pane.
---

# repo-deck-style

**Rule:** colour means identity. A kind's colour is its border, its title, its caret and its selected row - nothing else uses it.

## Palette (`tone` in `hooks/deck.tsx`; real values: `repo-deck-inspect`)

| Token | Role |
|---|---|
| `orange` | plugins; summary border (dimmed) |
| `violet` | commands |
| `green` | standalone skills |
| `lavender` | standalone hooks |
| `cyan` | standalone agents |
| `text` | primary text and values |
| `muted` | labels, secondary text, card right-hand value |
| `faint` | separators `·`, disabled text, timings |

Dark background comes from the terminal; never set `backgroundColor`.

## Layout

- Header: the marketplace name alone, centred, then a blank line; clicking it opens the repo in VS Code. No legend: each card already names its kind.
- One card per kind, in `SECTIONS` order; a kind with 0 rows draws no card.
- Card: `borderStyle="round"` in the kind colour; title row = `▾/▸ TITLE` (one Button: caret and title both collapse) + count on the right; no gap between cards.
- Row: `◇ name` (`◆` + kind colour when selected) + muted `meta · description`, cut to one row with `cut()`; names without the `marketplace:` prefix.
- Detail card: title = name, right = meta (full version, hook event); blank line; description as `Markdown` (backticks become code); blank line; buttons.
- Summary: `kind N · …` only for N > 0, then faint timing.

## Text

- Italian UI; buttons UPPERCASE, short verbs: `INSTALLA`, `USA NELLA CHAT`, `CHIEDI A CLAUDE`.
- List versions drop a zero patch (`v0.1`); the detail shows it whole (`v0.1.0`).
- No decorations the user removed: no ✓ in the summary, no subtitles after titles, no numeric hotkeys on cards, no "Chiudi"/"ricarica" buttons.

## Terminal limits

- Font size and family cannot change; emphasis = bold + colour only.
- `[ ]` around buttons is drawn by the terminal and cannot be removed.
- Border styles: `single double round bold singleDouble doubleSingle classic arrow dashed quote`.
