---
name: php-upgrade-workflow
description: Entry point for upgrading a legacy PHP site (Enesi "Master 7" / phplib, PHP 7.x in production) to PHP 8.x with the php-upgrade plugin — step order, shared rules, the project guard and how to keep the user in the loop without slowing down. Use when the user says "start the migration", "migrate to PHP 8", "next step of the migration", or when a project has _migration/config.sh. Not for Laravel projects.
---

# php-upgrade-workflow

**Golden rule:** behave exactly like production did before, with the smallest change that stops the fatal. Production is not yours: you prepare, the user uploads.

`PU=C:/Users/danilo/Dev/danilo-claude-skills/plugins/php-upgrade/scripts` — run every script with **Bash** (Git Bash) from the project root. Project data lives in `_migration/config.sh`; the step table with exact commands is `_migration/GUIA.md`.

## Order
| Step | Skill |
|---|---|
| set up `_migration/` (new project) | `mig-init` |
| L0-L1 environment + verified DB backup | `mig-backup` |
| L2 baseline + red tests, then every verification | `mig-test` |
| L3-L4 host on the new PHP + core/project patches | `mig-apply-core` |
| L5 third-party libraries (one at a time) | `mig-update-lib` |
| L7 every FAIL/WARN, admin errors, user reports | `mig-fix-runtime-error` |
| L9 report | `mig-report` |
| P0-P7 production | `mig-deploy-prod` (backup via the `prod-to-local` plugin) |
| undo | `mig-rollback` |

## Shared rules
- One step = one commit (Italian message). Never `git reset/checkout/restore/push/stash`, never `--amend`: undo with `$PU/rollback.sh`.
- The reference is **PROD's PHP (`PHP_PROD`)**, not the old local PHP: changes from 7.1-7.4 matter too (tests A1, A2).
- Third-party libraries are replaced whole (`update-lib.sh`), never edited. The core (Master 7) is patched minimally, never upgraded.
- Out of scope: deprecations that do not break output, refactoring, the DB, sacrificable features (`SACRIFICABLE` in config), errors that exist **only locally** (Windows paths, missing `it_IT` locale, `addslashes` on `$_FILES`): note them in REPORT and add them to the P6 manual checks.
- Never write in PROD, never `ssh/scp` yourself; give the user exact commands (PowerShell: `| Out-File -Encoding ascii`, not `>`; `tar -xzf`, not `-tzf`).

## Keep the user in the loop, but fast
- **Batch approvals by pattern.** When a fix is the same in N files (e.g. `count($x[..])` in 22 modules), grep the whole project first and ask once for all of them. Same for a family of errors (all `count(null)`, all missing arguments).
- Show `file:line`, cause, 1-3 line diff; for small, behaviour-identical fixes of an already-approved pattern, apply and report instead of asking again.
- Do not re-ask what is approved: a library version approved → download + SHA shown in the same message as the next action.
- Long or independent work (code scans per folder) → read-only subagents in parallel (max 3); you keep all edits and commits.
- When the user browses the admin, read `php_errors-<v>.log` yourself instead of asking them to paste errors.

## The guard (plugin hook, only in projects with `_migration/config.sh`)
Blocks writes to protected paths, git that changes state, SQL writes, direct PROD access, hand-written `ssh`. It reads `PROTECTED` and `PROD_HOST` from config. A blocked command **did not run**.
- If it is clearly a read-only command caught by mistake, rewrite it into separate simple commands once; never disguise the same action (no moving URLs into scripts to dodge it).
- Otherwise stop and ask. For harness maintenance the user creates `.claude/guard.off` (and removes it after).
- Claude Code's own permission classifier also blocks edits to the guard file itself: prepare the new version in the scratchpad and give the user a copy command.
