---
name: mig-init
description: Sets up _migration/ for a new PHP upgrade project with the php-upgrade plugin — config.sh, URL lists, patches/checks/SPEC from the Master 7 templates, mig/base tag. Use once per project, before mig-backup, when the user wants to start a PHP migration on a site that has no _migration/config.sh yet.
---

# mig-init

**Rule:** the repo must contain the site **exactly as in production**, committed and tagged `mig/base`, before anything changes.

## Steps
1. Check `git status` (site committed as in PROD). If the repo does not exist yet, ask the user: the baseline normally comes from a fresh PROD copy (`prod-to-local`).
2. `bash $PU/init.sh` — copies templates into `_migration/` without overwriting.
3. Fill `_migration/config.sh` with the user (ask in one round, propose what you can detect):
   - versions: `PHP_PROD` (from cPanel/`.htaccess` handler), `PHP_FROM` (old PHP available locally), `PHP_TO`;
   - `LOCAL_URL` (Dunebox host), `PROD_URL`, `PROD_HOST`, PROD SSH user/host/port and the **real** site path (`www` is often a link to `public_html`);
   - local DB; `SITE_PATHS` (tracked site files, include root files like `index.php`); `KEEP_UNTRACKED` (config the site writes itself); `PROTECTED` (per-domain config, media, third-party libraries).
4. Lists (one item per line, see `templates/lists.txt`): `urls.txt` (static pages + a sample of dynamic ones, every language), `urls-pdf.txt`, `urls-admin.txt` (from the admin menu, never `logout.php`), `urls-compare.txt`, `lint-ignore.txt`.
5. Analysis → `SPEC.md`, `patches.php`, `checks.php`, `libs.lock`: lint the whole site with the new PHP, run `run-tests.sh --static` (A1/A2 list 7.1+/8.0 fatals the lint cannot see), read the libraries' versions. Keep the Master 7 core patches C1-C6 only if `patch.php` (dry-run) finds them. Show the SPEC to the user and get approval.
6. Add `_migration/out/` to `.gitignore`, commit `_migration/`, `git tag mig/base` on the commit with the site as in PROD (ask the user before tagging).
7. Enable the plugin for the project in `.claude/settings.local.json` (`"enabledPlugins": {"php-upgrade@danilo-claude-skills": true}`) if it is not enabled globally.
