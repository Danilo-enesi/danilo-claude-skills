---
name: prod-preflight
author: Danilo-enesi
description: Read-only check of a production server before copying a site: SSH host key, login with the vault password, available tools (tar, gzip, sha256sum, mysqldump), free space in $HOME, site size and file count, leftovers from earlier runs. Use before prod-pull-code / prod-pull-db, or to find where the site lives on the server. Writes nothing on the server.
---

# prod-preflight

**Rule:** look before you touch. This step only reads.

## Steps

1. Tell the user: "I will log in to `<user>@<host>:<port>` with vault profile `<profile>` and run read-only checks." Ask permission.
2. Run (without `--site` it lists `$HOME` so you can find the site folder):
   ```
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/preflight.sh" --user <user> --host <host> --port <port> --profile <job>-ssh [--site <path>]
   ```
3. Exit code 3 = unknown host key. Show the user the printed fingerprints, and only if they confirm them, rerun with `--trust-host-key`.
4. Read the output and tell the user:
   - any `tool ...: MISSING`: stop. Never install anything on the server.
   - `site_mb` vs `free_home_mb`: the archive needs about `site_mb` + 100 MB free. If it does not fit, propose `--exclude` for big folders in the top-level listing (backups, logs, cache) and ask.
   - `leftover:` lines: temp files from an interrupted run. Tell the user; they can be removed with `prod-rollback` of that job.

## Rules

- The script runs exactly `remote/preflight.sh` from this plugin on the server: nothing else.
- `Connection timed out`: wrong port or IP restriction. Ask the user for the right port; do not scan ports on a production server.
