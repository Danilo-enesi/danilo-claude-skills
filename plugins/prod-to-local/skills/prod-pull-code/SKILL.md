---
name: prod-pull-code
author: Danilo-enesi
description: Copy the files of a site from a production server into a NEW local folder (default C:\devProjects\<job>) with checksum verification; all-or-nothing. Use after prod-preflight when the user wants the project's code/files on this PC. Never overwrites a local folder, never leaves files on the server.
---

# prod-pull-code

**Rule:** one archive, verified, then gone from the server.

## What the script does

1. On the server: `nice tar -czf $HOME/.prod-to-local-<job>-<time>.tgz` of the site (fails if free space is short).
2. Downloads it with `scp`, checks the SHA-256 against the server's.
3. Deletes the archive from the server.
4. Creates the destination folder and extracts it there.

Any failure: the whole job is rolled back (server archive, download, folder).

## Steps

1. Tell the user the source path, destination, excludes and that one archive will sit in their server `$HOME` for a few minutes. Ask permission.
2. Run (one `--exclude` per pattern, relative to the site root, e.g. `./backup`):
   ```
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/pull-code.sh" --job <job> --user <user> --host <host> --port <port> --profile <job>-ssh --site <path> [--dest /c/devProjects/<job>] [--exclude ./backup]
   ```
   Large sites take minutes: use a long timeout (600000) or `run_in_background`.
3. Report the `DONE:` line (files, size, folder). A `WARNING: some files changed` means the live site wrote files while archiving: normal, tell the user.

## Rules

- The destination must not exist. Pick another one; never delete the user's folder to make room.
- A `.prod-to-local.job` marker stays in the folder until the job is committed with `prod-rollback --forget`.
