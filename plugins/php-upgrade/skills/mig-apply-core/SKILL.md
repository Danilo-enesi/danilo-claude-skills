---
name: mig-apply-core
description: Puts the local host on the new PHP (Dunebox web ini included) and applies the approved minimal patches to the Master 7 core and project code from _migration/patches.php with patch.php. Use after the verified backup and the red tests (steps L3-L4 of a php-upgrade migration).
---

# mig-apply-core

**Rule:** only the patches in `_migration/patches.php` (= approved SPEC). Anything else goes through `mig-fix-runtime-error`.

## L3 — host on the new PHP
1. Host: `"php": "<PHP_TO>"` in `.dunebox/config.json` (MCP `set_host_php`). Commit it alone (`Host locale su PHP <PHP_TO>`).
2. The web server reads `C:/devConfig/php/php-<PHP_TO>.ini`, **not** the CLI php.ini. Check it with `env.sh`: `short_open_tag = On` if the site uses `<?`; `display_errors = Off` (otherwise warnings break PDFs and differ from PROD). Files outside the project are edited by the user (give the PowerShell one-liner, `-Encoding ascii`).
3. The user restarts the services. `run-tests.sh --smoke` must FAIL now (old code on new PHP).

## L4 — patches
1. Dry-run: `"$PHP_TO_BIN" $PU/patch.php` (PHP_TO_BIN from config/env.sh). Every line must say `modifica`/`crea`/`già applicata`.
2. Apply: same with `--apply`.
3. Verify: `run-tests.sh --static` → C*/P* PASS (if a method check fails with the patch applied, suspect `short_open_tag`, not the patch); touched files compile on the old PHP too: `bash $PU/lint.sh from <files>`.
4. Show `git diff --stat` and the diff, commit `PHP <PHP_TO>: correzioni minime core e progetto (C…, P…)` with only the site files.

## If it fails
`patch.php` writes nothing when a text is missing or ambiguous: the code differs from the analysis. Then, or if a check fails: `bash $PU/rollback.sh`, stop and report.
