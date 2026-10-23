---
name: mig-rollback
description: Undoes a php-upgrade step or the whole migration, locally (git + host + DB) or in production (instructions for the user). Use when a step fails, a fix makes things worse, or the user asks to go back.
---

# mig-rollback

**Rule:** undo with the tools, never with `git reset/checkout/restore`.

## LOCAL
- Step in progress: `bash $PU/rollback.sh --dry-run` (shows what changes and what would be deleted), then `bash $PU/rollback.sh`. It also unstages files `update-lib.sh` added, and never deletes `KEEP_UNTRACKED`.
- Whole migration: `bash $PU/rollback.sh mig/base`, commit that state, host back to the old PHP (`.dunebox/config.json`) and restart services.
- DB (only if something wrote to it): `bash $PU/restore-db.sh <verified dump> --confirm`.

## PROD (the user does it, ~5 minutes; maintenance block on while doing it)
1. cPanel › MultiPHP Manager → `PROD_PHP_HANDLER_FROM`.
2. In the real site root: delete what `rollback-delete.txt` lists, upload and extract `rollback.tar.gz` (from the same `out/deploy-*/`).
3. `bash $PU/smoke.sh --target prod --confirm-prod`.
The DB does not change with the migration; only if needed the user imports the P1 dump (phpMyAdmin).
