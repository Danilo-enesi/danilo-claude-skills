---
name: repo-deck-check
author: Danilo-enesi
description: Verify a change to the repo-deck mod - consistency check, claude plugin validate, claude plugin test, then a live look in a session loaded from the repo folder. Use after every repo-deck edit and before saying it works or committing. Only checks; it does not fix.
---

# repo-deck-check

**Rule:** "validates" is not "works": the last step is seeing the pane in a session.

## Steps

From the repo root:

1. Consistency (palette, state contract, hotkeys, marketplace entry):
   ```
   python -I mods/repo-deck/skills/repo-deck-inspect/scripts/inspect.py mods/repo-deck --check
   ```
2. Validate + tests:
   ```
   bash mods/mod-kit/scripts/check.sh mods/repo-deck
   ```
   Must end with `✔ Validation passed` and `0 fail`. The README/LICENSE/icon block is about publishing to the plugin directory: ignore it.
3. Live: ask the user to start `claude --plugin-dir mods/repo-deck` and run `/repo-deck`. The installed copy keeps running the old version until `repo-deck-release`.
4. A broken render shows in that session as `repo-deck: ui.render hook skipped: ...`: the reason names the refused element.

## Notes

- Report what failed with its output; never call it done on a failing step.
