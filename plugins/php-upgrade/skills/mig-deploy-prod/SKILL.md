---
name: mig-deploy-prod
description: Takes a finished php-upgrade migration to production — PHP ini and translations check, verified PROD backup, deploy package, maintenance page on/off, deploy via SSH with snapshot and automatic rollback, PHP version switch by the user, smoke and comparison in PROD. Use only with the report ready and the user's explicit go-ahead.
---

# mig-deploy-prod

**Rule:** production is touched only by the plugin's fixed scripts (`deploy-push.sh`, `deploy-rollback.sh`, `maintenance.sh`), each run approved by the user (the guard asks every time). Never hand-written `ssh`/`scp`. The PHP version switch and anything in cPanel stay with the user.

## Gates (in order)
1. `_migration/REPORT.md` says «pronto per PROD». Banner (`env.sh`) + one AskUserQuestion: «Next step: PRODUCTION».
2. **P0** (user): `prod-php<XX>-modules.txt` and `-ini.txt` (commands in GUIA). `env.sh`: no missing extension, `short_open_tag => On` (if the site uses `<?`), `display_errors => Off`; user checks cPanel › MultiPHP INI Editor. UTF-16 file → convert with `iconv`, don't ask again.
3. **P1-P2**: fresh verified PROD backup (`mig-backup` › PROD). The vault profile `PROD_VAULT_PROFILE` (config) must exist: it is the same password used by prod-to-local.
4. Data that stays in PROD (never in the package): `bash $PU/lang.sh missing <PROD copy>` and A2 on the copy. Missing translations → the user fills them in Admin › Linguaggi **before** P5.

## Package (P3)
`bash $PU/deploy-pack.sh --prod-copy <dir> --prod-dump <dump> --dry-run`, then without `--dry-run`. It excludes `KEEP_UNTRACKED` (PROD's config and translations win), compares raw bytes with `mig/base`, writes `deploy-manifest.txt` (base SHA of every changed file + SHA of every packaged file). It stops if PROD changed: report which files, never force.

## Run (one approval per command)
| Step | Command | What happens |
|---|---|---|
| P3b maintenance ON | `bash $PU/maintenance.sh on` | uploads `_migration/manutenzione.html` (only if absent), inserts the 503 block right after `RewriteEngine On`, excluding the IP this PC uses (seen by the server over SSH + public HTTP IP). Adds lines only, verified byte by byte. The script checks this PC still gets 200; ask the user to check the 503 from a phone without wifi |
| P4 deploy | `bash $PU/deploy-push.sh --pack <out/deploy-…> --dry-run` then without `--dry-run` | re-checks PROD = `mig/base` by SHA-256 on the server, snapshots what changes into `~/.php-upgrade/<job>/before.tgz`, deletes whole library folders, extracts, verifies every file's SHA; any failure restores the snapshot automatically |
| P5 PHP | the user: cPanel › MultiPHP Manager → `PROD_PHP_HANDLER_TO` | |
| P6 verify | `smoke.sh --target prod --confirm-prod`, `compare-prod.sh --confirm-prod --shots` | GET only, pass the maintenance block (same IP). User: `error_log` (today's Fatal), manual checks from REPORT (upload, PDFs behind login, a form with real SMTP, locale, every language) |
| P7 maintenance OFF | `bash $PU/maintenance.sh off` | removes **only** the block it added (refuses if it was edited by hand) and the page if it created it unchanged |

- Something wrong after P4/P5 and it affects visitors → maintenance stays ON; propose `bash $PU/deploy-rollback.sh --pack <out/deploy-…>` (restores the snapshot, verified against `mig/base`) plus the user switching back to `PROD_PHP_HANDLER_FROM`.
- A contained one-file issue → `mig-fix-runtime-error` locally, new package (`deploy-pack.sh`), `deploy-push.sh` again (new job).
- Manual fallback (no SSH access): `deploy.tar.gz` + `deploy-delete.txt` / `rollback.tar.gz` + `rollback-delete.txt` with cPanel File Manager; the maintenance block from GUIA pasted by the user.

## Close
Repeat the PROD smoke once after P7. Append the PROD section to REPORT (backup paths, package, job), commit, tag `mig/done`, offer to remove the vault profiles.
