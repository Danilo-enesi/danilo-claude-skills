---
name: mig-backup
description: Verified backup for a php-upgrade migration — local DB (dump + test restore) or production (files + DB via the prod-to-local plugin, then verify). Use before changing anything and again before deploying to production.
---

# mig-backup

**Rule:** a backup counts only once it has been restored as a test. No `.verified`, no next step.

## LOCAL
1. `bash $PU/env.sh` → `AMBIENTE: LOCAL`, no missing extension, no ini warning. If MySQL is unreachable, the user starts Dunebox services.
2. Site files are in git (`mig/base`); `git status` clean.
3. `bash $PU/backup-db.sh` → imports into `DB_VERIFY`, compares tables and rows, writes `<dump>.verified`.

## PROD (before the deploy)
1. Tell the user in one message: a copy of PROD (files + DB) is downloaded with `prod-to-local`; on the server only a temp file in `$HOME`, removed right after. Confirm the plan once (prod-to-local-workflow), then follow its skills without re-asking at every script (its hook asks permission anyway).
2. Use `PROD_SSH_*` and the **real** site path from config: if the preflight says `site_mb=0`, the path is a link — rerun with the target (`public_html`).
3. DB user: from the user or the copied config, **names only**, never read passwords. Charset from the local dump (`DEFAULT CHARSET`).
4. `bash $PU/backup-db.sh --verify <prod dump>` → `.verified`. Then `prod-rollback --forget` after the user's ok; keep vault profiles until the end of the migration.

Done when: PROD folder + dump with `.verified`. Write both paths in REPORT: `mig-deploy-prod` needs them.

## If it fails
Stop and report the error. Do not retry at random, do not continue without a backup.
