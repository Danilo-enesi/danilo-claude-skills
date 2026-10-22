---
name: prod-to-local-workflow
author: Danilo-enesi
description: Entry point to copy a site from a PRODUCTION server to this PC (files + database dump) over SSH as one all-or-nothing job. Use when the user says "bring/copy/download the project from the server", "pull the site from prod", "clone prod locally", "llevar el proyecto del server a local". Only gives the order of the prod-to-local skills; each step is its own skill. Does NOT create local hosts, import the DB or edit the site config.
---

# prod-to-local-workflow

**Rule:** production is not yours. Ask, explain, then let the scripts act. You never type a command on the server yourself.

## Order

| # | Skill | Does | Touches the server |
|---|---|---|---|
| 1 | `prod-vault` | user stores SSH (and DB) passwords | no |
| 2 | `prod-preflight` | checks host key, login, tools, free space, site path | read-only |
| 3 | `prod-pull-code` | site files -> new local folder | 1 temp file in `$HOME`, removed |
| 4 | `prod-pull-db` | DB dump -> new local `.sql.gz` (optional) | 1 temp file in `$HOME`, removed |
| 5 | `prod-rollback --forget` | commits the job | no |

If any step fails, its script has already rolled back the **whole job** (server temp files, downloads, project folder). Report the error; do not retry blindly.

## Before step 2: confirm the plan

Gather and show the user, then ask with `AskUserQuestion` (one question, "Proceed" / "Change something"):

- server: `user@host`, SSH port, site path on the server
- job name (short, e.g. the project name) and local destination (default `C:\devProjects\<job>`, Git Bash: `/c/devProjects/<job>`)
- excludes (backups, logs, caches) if the preflight shows a big site
- DB: name, DB user, vault profile (only if step 4 is wanted)
- what will be written on the server: one archive/dump in `$HOME`, deleted right after download

## Shared rules

- Run the scripts with the **Bash** tool (Git Bash), never PowerShell: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/<script>.sh" ...`.
- Before **every** script that uses the vault (all of steps 2-5), tell the user in one line what it will do and ask permission. The plugin hook also forces a permission prompt; that does not replace your explanation.
- Never: `sudo`, installing packages, editing files on the server, `ssh` commands written by hand, reading the vault, `vault.ps1 get`.
- No access as root: if the preflight says a tool is MISSING, stop and tell the user. Do not work around it.
- Same `--job` for steps 3-5. Never reuse an existing destination: the scripts refuse to overwrite.
- What to do with the copy afterwards (host, DB import, config) is out of scope: say so and stop.
