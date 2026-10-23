---
name: repo-deck-release
author: Danilo-enesi
description: Ship a checked repo-deck change to the user's installed copy - bump the version, commit, push, refresh the marketplace and update the user-scope plugin. Use when the user says "publica/instala la nueva versión de repo-deck", "aggiorna repo-deck installato", "release repo-deck". Only after repo-deck-check passes; push only on the user's request.
---

# repo-deck-release

**Rule:** no version bump, no update: Claude Code installs by version, so an unchanged version keeps the old copy.

## Steps

From the repo root:

1. `repo-deck-check` passes.
2. Bump: `patch` for fixes and text, `minor` for new features.
   ```
   python -I mods/repo-deck/skills/repo-deck-release/scripts/bump.py minor mods/repo-deck
   ```
3. Commit with skill `commit-to-main` (Italian message).
4. Push only if the user asked: `git push origin master`.
5. Refresh and update the installed copy:
   ```
   claude plugin marketplace update danilo-claude-skills
   claude plugin update repo-deck@danilo-claude-skills
   ```
   First install: `claude plugin install repo-deck@danilo-claude-skills --scope user`.
6. Tell the user to run `/reload-plugins`, then `/repo-deck`.

## Notes

- The marketplace is registered as a local folder: the update copies from the working tree. Commit first so the installed copy matches git.
