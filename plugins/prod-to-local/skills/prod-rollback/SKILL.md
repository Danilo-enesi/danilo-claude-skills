---
name: prod-rollback
author: Danilo-enesi
description: Undo or commit a prod-to-local job. Undo removes everything the job created (temp files on the server, downloads, the new project folder), newest first; --forget commits a finished job. Use when a job was interrupted, when prod-preflight shows "leftover:" files, when the user says "cancel/undo the copy", or as the last step of prod-to-local-workflow.
---

# prod-rollback

**Rule:** it only deletes what its job created and recorded.

The ledger is `~/.prod-to-local/jobs/<job>.ledger`. A folder is deleted only if its `.prod-to-local.job` marker names the same job.

## Undo (failure, interruption, user cancels)

1. Show the user the ledger contents (`cat ~/.prod-to-local/jobs/<job>.ledger`) and say what will be deleted. Ask permission: it may log in to the server to delete the temp file.
2. Run:
   ```
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/rollback.sh" --job <job>
   ```
3. `rollback incomplete` = something could not be deleted (printed with `!!`). The ledger is kept: tell the user exactly what is left and where.

## Commit (job finished well)

1. Ask the user if the copy is OK, then:
   ```
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/rollback.sh" --job <job> --forget
   ```
   It refuses while server files are still listed. After this the job can no longer be undone.
2. Offer to remove the vault profiles (`prod-vault remove`), if the user wants.
