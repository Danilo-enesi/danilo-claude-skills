---
name: repo-deck-workflow
author: Danilo-enesi
description: Entry point for maintaining the repo-deck mod (the /repo-deck terminal pane of the danilo-claude-skills marketplace) - what each file does, the edit/check/release loop and which repo-deck skill does each step. Use when asked to change, fix, extend or understand repo-deck ("modifica repo-deck", "aggiungi un bottone al pane", "il pane non mostra X", "how does repo-deck work"). Only maps the work; each step is its own skill.
---

# repo-deck-workflow

**Rule:** facts come from `repo-deck-inspect`, never from memory; one skill per step; the source of truth is `mods/repo-deck/` in the repo, never the installed copy in `~/.claude/plugins/cache`.

## Map

| File | Holds |
|---|---|
| `hooks/register.tsx` | the pane: `/repo-deck` command, state atoms, `SECTIONS`, cards, detail card, buttons and their actions |
| `hooks/deck.tsx` | the Flightdeck kit: `tone` palette, `Header`, `Card` (collapsible), `Meter`, `Kv`, `cut`, `fill` |
| `hooks/scan.ts` | reads `marketplace.json` and the root `skills/ commands/ agents/ hooks/` into the catalog |
| `hooks/install.ts` | INSTALLA of a hook: merges it into `.claude/settings.local.json` |
| `types/index.d.ts` | `Entry`, `Catalog`, `Kind` and the `$.state` contract |
| `hooks/*.test.ts` | tests of the pure functions (`claude plugin test`) |
| `.claude-plugin/plugin.json` | name, version |

## Order

| # | Skill | When |
|---|---|---|
| 1 | `repo-deck-inspect` | always first: palette, sections, atoms, buttons, free hotkeys, problems |
| 2 | `repo-deck-style` | before any visual change: the design rules of the pane |
| 3 | `repo-deck-edit-pane` | change layout, text, buttons or actions |
| 4 | `repo-deck-edit-scan` | change what is listed or the data of an entry |
| 5 | `repo-deck-check` | after every edit |
| 6 | `repo-deck-release` | when the user wants the change installed |

## Shared rules

- Work from the repo root; paths below are relative to `mods/repo-deck/`.
- UI text is Italian and buttons are UPPERCASE; skills and code comments are English.
- Commit only when the user asks (skill `commit-to-main`).
