---
name: repo-deck-inspect
author: Danilo-enesi
description: Print the deterministic facts of the repo-deck mod - version, command, palette with hex and uses, sections with their colour, state atoms with shape tags, every button with key/hotkey/label/line, free hotkeys, files - and flag inconsistencies. Use before changing repo-deck, when you need "the colours", "which hotkeys are free", "which atoms exist", or to verify a change did not break the palette/state contract. Only reads; never edits.
---

# repo-deck-inspect

**Rule:** run the script, do not re-read the code to answer what it already prints.

## Steps

1. From the repo root:
   ```
   python -I mods/repo-deck/skills/repo-deck-inspect/scripts/inspect.py mods/repo-deck --check
   ```
   Without a path it inspects the mod the script ships in. `--json` for the full structure.
2. Read `problems:`. Exit code 1 means at least one:
   - a section colour missing from `tone` (`hooks/deck.tsx`);
   - an atom not declared in `types/index.d.ts`, or a declared state no atom uses;
   - a hotkey used twice, or not one digit / lowercase letter;
   - inside the repo, no `marketplace.json` entry with source `./mods/repo-deck`.

## Output

- `palette`: `name #hex (uses in register.tsx)`; `sections`: `TITLE=colour`
- `atoms`: `key@shape`; `button`: line, key, hotkey, label (`{…}` = computed)
- `free hotkeys`: letters still free for a new button

## Notes

- Regex-based on the current code shape (`SECTIONS` entries, `atom(... { shape })`). If you restructure those, update `scripts/inspect.py` in the same change.
