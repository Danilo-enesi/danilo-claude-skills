# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

This repo is simultaneously a Claude Code **marketplace** and the single **plugin** it distributes. `.claude-plugin/marketplace.json` defines the marketplace and points to one plugin whose source is `./` (this same repo); `.claude-plugin/plugin.json` holds that plugin's metadata (name, version, description, author). There is no build, lint, or test tooling — this is a content repo of Claude Code skills/commands/agents, not application code.

## Structure

```
danilo-claude-skills/
├── .claude-plugin/
│   ├── marketplace.json   ← marketplace definition, lists the plugin
│   └── plugin.json        ← plugin metadata (bump version on changes)
├── skills/                ← skills (SKILL.md + resources)
├── commands/              ← slash commands (*.md)
├── agents/                ← sub-agents (*.md)
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

## Skill authoring conventions observed in this repo

- State a one-line "regola d'oro" / mental model near the top of the skill body before going into detail.
- Read-only / analysis-only skills (e.g. `master-code-review`) explicitly say in their description that they only report findings and never write or modify code — preserve that distinction when editing them.
- Skills scoped to the Master Laravel Enesi framework assume familiarity with its module/config.php/Field/Blade conventions; don't genericize them into framework-agnostic advice.
