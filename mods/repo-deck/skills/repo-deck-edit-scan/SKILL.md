---
name: repo-deck-edit-scan
author: Danilo-enesi
description: Change what repo-deck lists or what an entry carries - which plugins/skills/commands/hooks/agents are read, their name, description, meta or action data - in hooks/scan.ts and types/index.d.ts. Use for "list also the skills inside plugins", "show the hook matcher again", "read X from the frontmatter", "the deck does not find the marketplace". Does not change how entries are drawn (repo-deck-edit-pane).
---

# repo-deck-edit-scan

**Rule:** whenever the shape of `Catalog` or `Entry` changes, bump the catalog atom's `shape` tag (`catalog-3` -> `catalog-4`), or the value stored by the old version comes back with the old fields.

## How the scan works

1. Root: the project folder (`projectRoot` in `hooks/install.ts`: where the session started, never the moving `$.session.cwd()`) if it has `.claude-plugin/marketplace.json`, else `installLocation` of `danilo-claude-skills` in `~/.claude/plugins/known_marketplaces.json`.
2. Each `marketplace.json` plugin with a non-root source -> one `plugin` entry (`meta` = `v<version>`, `invoke` = `/plugin install` args).
3. Only the root plugin (source `./`) is scanned for `skills/*/SKILL.md`, `commands/*.md`, `agents/*.md`, `hooks/hooks.json`: these are the standalone ones.
4. Hook: name = script file, description = first comment of the script, `meta` = event, `install` = event + matcher + command with `${CLAUDE_PLUGIN_ROOT}` made absolute.

## Steps

1. Edit `hooks/scan.ts`; keep parsing in exported pure functions (`frontmatter`, `hookScript`, `firstComment`, `shortVersion`).
2. New field: add it to `Entry`/`Catalog` in `types/index.d.ts` and bump the `shape` tag of `catalog` in `hooks/register.tsx`.
3. Add or extend a case in `hooks/scan.test.ts` for each new pure function.
4. Run `repo-deck-check`.

## Notes

- `$.fs` only: no Node, no `require`; reads are capped at 4 MiB per file.
- Windows paths: convert `\` to `/` before building paths or bash commands.
