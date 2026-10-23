---
name: mig-fix-runtime-error
description: Decides and applies the minimal fix for a runtime error after a PHP upgrade (smoke FAIL/WARN, admin error, user report, production error_log) — fix pattern-wide, note it, or leave it as local-only/sacrificable. Use for every FAIL/WARN line of the php-upgrade smoke and every error the user pastes during the migration.
---

# mig-fix-runtime-error

**Rule:** the result must be what PROD's old PHP produced, with the smallest change — and the same fix everywhere the pattern repeats.

## Finding the error
- 500 with nothing in the log: in Master sites `front/lib/Admin/Boot.php` (`loadAdmin`) runs `error_reporting(0)`, hiding later fatals. Check first the **web** ini (`env.sh`: `short_open_tag`), then `php_errors-<v>.log`; reproduce in CLI with `-d error_reporting=-1` if needed.
- Master ajax endpoints (e.g. `admin/upload.php`) answer errors with JSON and HTTP 200: ask the user for the Response in F12 › Network.
- After the user browses the admin, read the log yourself (time window), group by message.

## Decide
0. **Only local?** (Windows `\` paths, `it_IT` locale, `addslashes` on `$_FILES` → upload `code 103`): code identical to `mig/base` and caused by the environment → do not fix; note it and add it to the P6 manual checks.
1. **Existed before?** The reference is PROD's PHP. The old local PHP log helps only for messages that exist in both. Existed and harmless → note it.
2. **Sacrificable feature** (`SACRIFICABLE` in config)? → note it; hiding its UI entry is a separate request of the user.
3. **Inside a third-party library?** → never edit it; fix the caller or update the library (`mig-update-lib`). Ask the user.
4. **Breaks** (Fatal, TypeError, ValueError, different page)? → minimal fix in project/core code:
   - grep **the whole project** for the same pattern first; propose one fix for all occurrences (1-3 lines each) with `file:line`, cause and diff; wait for the ok once per pattern;
   - same result as before: `count(null)`→0 (`!empty()`), `in_array(x, null)`→false (`(array)`), missing argument→`null` (`= null` default), undefined constant→its name or `''` (`defined() ? X : ''`, or add the term in Admin › Linguaggi when it is a translation constant), `max([])`→`false`, `trim(array)`→`null`, division by zero→guard;
   - missing translations (A2 `traduzione mancante`, A3): the fix is data, not code — `bash $PU/lang.sh sql` prints an idempotent INSERT with the other language's text as placeholder (translate it first). LOCAL, only if the user asks: verified `backup-db.sh`, run the SQL, `lang.sh regen` (same output as «Aggiorna i linguaggi», check `git diff` shows only those lines). PROD: the user adds the values in Admin › Linguaggi (or runs the SQL in phpMyAdmin) and presses «Aggiorna i linguaggi»;
   - other seen patterns: `call_user_func_array` with string keys (`array_values()`), by-reference param on `null->prop` (pass by value), `constant()` on a missing constant, `ReflectionParameter::getClass()` (`getType()`);
   - must compile on the old PHP too: `bash $PU/lint.sh from <file>`; no refactoring, no nearby deprecation cleanup.
5. **Warning that does not change the result** (ex-Notice) → do not touch, note it as «solo avviso». Exception: anything printed inside a PDF breaks it.
6. In doubt → do not change, note «da verificare».

## After a fix
- Rerun the smoke: that FAIL/WARN must disappear and no new one appear. `run-tests.sh --static` (A1/A2) still PASS.
- Separate commit: `PHP <PHP_TO>: <file or pattern> — <problem in 5 words>`.
- One line in `_migration/REPORT.md` (corrections). Errors left as they are go in the "non corretti" table with the decision.
- A fix found **in PROD**: fix locally, test, commit, give the user the single-file upload command; propose rollback instead if the error affects visitors and the fix is not trivial.

## If the fix makes it worse
`bash $PU/rollback.sh` and stop.
