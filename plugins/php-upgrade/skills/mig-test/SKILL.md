---
name: mig-test
description: Runs and reads the php-upgrade tests — static checks (project checks, lint G1, missing arguments A1, undefined constants A2), front/admin smoke, LOCAL vs PROD comparison and the guard test. Use to prove red tests before migrating and to verify every step.
---

# mig-test

| Command | When |
|---|---|
| `bash $PU/smoke.sh --target local --record` | once, site still on the old PHP: reference HTTP statuses |
| `bash $PU/run-tests.sh --static --expect-red` | **before** touching code: every test must fail (A2 may already pass: informative). A test that passes detects nothing: tell the user |
| `bash $PU/run-tests.sh --static` | after every step |
| `bash $PU/run-tests.sh --smoke` | host on the new PHP: same statuses as the reference, valid PDFs, no Fatal (front only) |
| `bash $PU/smoke.sh --target local --admin-cookie 'NAME=VALUE'` | admin modules with the user's session (F12 › Application › Cookies); a 302 = expired session |
| `bash $PU/compare-prod.sh --confirm-prod [--shots]` | visible text (and screenshots) LOCAL vs PROD, GET only, after the user's ok |
| `bash $PU/lang.sh missing [DIR]` | A3 on its own: front translations present in one language and missing in another; `DIR` = the PROD copy (language files are not deployed, PROD's state is what counts) |
| `bash $PU/tests/selftest.sh` (in the plugin) / `python -I .../tests/guard_test.py` | after changing the plugin / the guard |

## Reading results
- `FAIL` = broken (HTTP differs from the reference, PDF not generated, Fatal/Parse/Uncaught in page or log). Step not done.
- `WARN` = PHP warning: does not block, each one goes through `mig-fix-runtime-error`.
- `log x…` lines also count what the user did in the browser during the smoke.
- A single `503`/timeout locally is usually Dunebox's FastCGI being busy: retry that URL before investigating.
- 0 FAIL is not enough: the admin and data-dependent fatals (new form, save, empty fields) only show up by browsing. Before the report the user tries the admin (list, new, edit, save, search).
- A1/A2 failures list `file:line`: real ones get fixed (pattern-wide), verified false positives go into `argcount-ignore.txt` / `const-ignore.txt` with the reason.
- A2 rule: a constant is safe only with a `defined()` fallback, a `define`/`const` in code, or — for translations — a value in the language files (front: **every** language, only one file is loaded; admin: one is enough, the default fills the rest). `traduzione mancante in: eng` → add the value in Admin › Linguaggi (no code change). `senza definizione né fallback` → decide: new translation term, or config constant with `defined('X') ? X : ''`.
