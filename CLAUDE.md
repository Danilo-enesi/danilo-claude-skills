# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This repo is a Claude Code **marketplace** that distributes three plugins. `.claude-plugin/marketplace.json` lists them: `danilo-claude-skills` with source `./` (the repo root; metadata in `.claude-plugin/plugin.json`), `pdf-design` with source `./plugins/pdf-design` (its own `.claude-plugin/plugin.json`, `skills/`, `README.md`), and `prod-to-local` with source `./plugins/prod-to-local` (same layout plus `scripts/`, `remote/`, `hooks/`, `tests/`). The root plugin only loads the root `skills/`, so they never mix. A self-contained group of related skills goes in its own plugin under `plugins/<name>/`; bump that plugin's own version on changes. There is no build, lint, or test tooling — this is a content repo of Claude Code skills/commands/agents, not application code.

## Structure

```
danilo-claude-skills/
├── .claude-plugin/
│   ├── marketplace.json   ← marketplace definition, lists the plugin
│   └── plugin.json        ← plugin metadata (bump version on changes)
├── skills/                ← skills (SKILL.md + resources)
├── commands/              ← slash commands (*.md)
├── agents/                ← sub-agents (*.md)
├── hooks/                 ← hooks.json + scripts (active wherever the plugin is enabled)
├── plugins/
│   ├── pdf-design/        ← separate plugin: PDF design comprehension (skills + Python scripts, all English)
│   └── prod-to-local/     ← separate plugin: copy a site from a production server to this PC (bash scripts, DPAPI vault, all English)
└── README.md
```

Most of the current skills are domain knowledge for the **Master Laravel Enesi** CMS ecosystem (`master-core-fields`, `master-code-review`, `master-front-rules`, `master-page-content`, `template-to-blade`), plus two meta/workflow skills for orchestrating Claude Code itself (`project-manager`, `subagent-empowerment`).

## Language convention

- Repo documentation (README, commit messages, notes): **Italian**.
- Skill definitions (`SKILL.md` — name, `description`, and body content): **English**, per Claude Code convention, since the `description` is what the model reads to decide whether to activate the skill and English keeps it consistent with the rest of the ecosystem.

## Adding a new skill

1. Create `skills/<skill-name>/SKILL.md` with `name` and `description` frontmatter **in English**. The `description` is the activation trigger the model matches against — make it specific about when to fire (typical trigger phrases) and, if relevant, what the skill explicitly does *not* do.
2. Add any supporting resources in the same folder.
3. Bump the version in `.claude-plugin/plugin.json`.
4. Commit + push.

## Adding a command or sub-agent

- Commands: `commands/<name>.md`
- Sub-agents: `agents/<name>.md`
- Hooks: register in `hooks/hooks.json` (script via `${CLAUDE_PLUGIN_ROOT}/hooks/...`). The plugin is enabled globally, so a hook must self-gate on the project (e.g. `block-lang-edits.sh` exits 0 unless `ln_upd.php` exists).

## Skill authoring conventions observed in this repo

- State a one-line "regola d'oro" / mental model near the top of the skill body before going into detail.
- Read-only / analysis-only skills (e.g. `master-code-review`) explicitly say in their description that they only report findings and never write or modify code — preserve that distinction when editing them.
- Skills scoped to the Master Laravel Enesi framework assume familiarity with its module/config.php/Field/Blade conventions; don't genericize them into framework-agnostic advice.
