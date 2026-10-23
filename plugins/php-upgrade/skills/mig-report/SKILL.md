---
name: mig-report
description: Writes the final one-page report of a php-upgrade migration (_migration/REPORT.md) with readable diff, what was done and what was not. Use when LOCAL is finished (static all PASS, smoke 0 FAIL, admin tried by the user), before the production deploy, and to append the PROD outcome at the end.
---

# mig-report

Prerequisite: `run-tests.sh --static` all PASS and the last smoke with 0 FAIL. Otherwise the report says so at the top.

Write `_migration/REPORT.md` (one page; keep the correction lines added during L7):
1. **Esito**: one line (ready for PROD yes/no and the PROD ini conditions, e.g. `short_open_tag = On`).
2. **Fatto**: table `commit | files | what` from `git log --oneline mig/base..HEAD` and `git diff --stat mig/base HEAD -- <SITE_PATHS>`; group pattern-wide fixes.
3. **Librerie**: name, version before → after (`libs.lock`), files kept.
4. **Non fatto**, with reason: differences from SPEC, sacrificable, already broken before, dead code, only-local errors, WARN left, **to test in PROD** (upload, PDFs behind login, form sending with real SMTP, locale-dependent output).
5. **Test**: last `run-tests.sh --static` output and smoke summary (`N richieste, 0 FAIL, M WARN`), LOCAL vs PROD comparison.
6. **Diff**: `git diff mig/base HEAD -- <SITE_PATHS> ':(exclude)<library dirs>'` into `_migration/out/diff-codice.patch` (libraries only as diffstat).

Show the summary and the diff path. Commit: `Migrazione PHP <PHP_TO>: report`. After the deploy, append a short PROD section (backup paths, package, smoke, fixes done in PROD) and close.
