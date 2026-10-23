---
name: mig-deploy-prod
description: Takes a finished php-upgrade migration to production — PHP ini check, verified PROD backup, deploy package, maintenance page, exact upload/extract commands for the user, PHP version switch, smoke and comparison in PROD. Use only with the report ready and the user's explicit go-ahead.
---

# mig-deploy-prod

**PROD is not yours.** You prepare and verify; the user uploads files, edits `.htaccess` and switches PHP. Ask for the go-ahead once at the start, then guide step by step without re-asking what the user already does.

## Gates (in order)
1. `_migration/REPORT.md` says «pronto per PROD».
2. Banner (`env.sh`) and one AskUserQuestion: «Next step: PRODUCTION».
3. **P0** (user): two `ssh` commands → `_migration/prod-php<XX>-modules.txt` and `-ini.txt` (exact PowerShell commands in GUIA: filter on the server with `grep` inside the quotes, `| Out-File -Encoding ascii`). `env.sh` must show no missing extension, `short_open_tag => On` (if the site uses `<?`: without it the whole front is 500) and `display_errors => Off`; the user also checks cPanel › MultiPHP INI Editor for the domain. If a file came out UTF-16, convert it (`iconv -f UTF-16 -t ASCII`) instead of asking again.
4. **P1-P2**: fresh verified PROD backup (`mig-backup` › PROD).
5. Data that stays in PROD (not in the package): `bash $PU/lang.sh missing <PROD copy>` and A2 on the copy (`MIG_ROOT=<PROD copy> "$PHP_TO_BIN" -d short_open_tag=1 $PU/scan-undefconst.php`). Every missing translation is a fatal waiting on the new PHP: the user fills it in Admin › Linguaggi **before** P5.

## Package (P3)
`git status` clean (untracked config in `KEEP_UNTRACKED` is ignored), then `bash $PU/deploy-pack.sh --prod-copy <dir> --prod-dump <dump> --dry-run`, then without `--dry-run`. It stops if PROD changed since `mig/base`: stop and report which files, never force. Check the tarball contains no protected file.

## Instructions to the user (P3b-P5), one message
- **P3b maintenance ON**: upload `manutenzione.html` (template in the plugin, adapt logo/colour/name; static, no PHP), paste the 503 block from GUIA after `RewriteEngine On` with the user's public IP (get it with `curl -s https://api.ipify.org`, write the escaped regex for them). Check from a phone without wifi.
- **P4**: in the **real** site root: delete what `deploy-delete.txt` lists (whole library folders), upload and **extract** `deploy.tar.gz`, remove it. Offer both File Manager and a single `ssh "cd <root> && sha256sum -c … && rm -rf <libs> && tar -xzf deploy.tar.gz && rm deploy.tar.gz && ls -d <key files>"` command; explain each part.
- **P5**: cPanel › MultiPHP Manager → `PROD_PHP_HANDLER_TO`.

## Verify (P6) after the user's «fatto»
- `bash $PU/smoke.sh --target prod --confirm-prod` and `bash $PU/compare-prod.sh --confirm-prod --shots` (GET only; they pass the maintenance block because they run from the user's IP).
- Everything 500 right after P4 usually means the archive was listed (`-t`) instead of extracted (`-x`), or `short_open_tag` is Off.
- The user checks `error_log` (today's Fatal) and does the manual checks from REPORT (upload, PDFs behind login, a form with real SMTP, locale).
- Any FAIL that affects visitors → propose rollback right away (maintenance stays on meanwhile). A contained one-file issue → `mig-fix-runtime-error` locally, then the user uploads that file.

## Close (P7)
The user removes the maintenance block; repeat the PROD smoke once. Append the PROD section to REPORT, commit, tag `mig/done`, offer to remove the vault profiles.
