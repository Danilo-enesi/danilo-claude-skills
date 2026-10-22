---
name: prod-vault
author: Danilo-enesi
description: Store, list or remove the passwords (SSH login, remote MySQL) that the prod-to-local scripts use, without Claude ever reading them. Use before prod-preflight / prod-pull-code / prod-pull-db when a vault profile is missing, or when the user says "save the server password", "change the password", "remove the credentials". Never reads a secret back.
---

# prod-vault

**Rule:** the user types secrets in a Windows dialog; you only handle profile names.

Secrets live in `%USERPROFILE%\.prod-to-local\vault\<profile>.cred`, encrypted with Windows DPAPI (only this user on this PC can decrypt). The scripts pass them straight to `ssh` (askpass) or to the remote `mysqldump` (stdin). A plugin hook blocks any direct read.

## Steps

1. Pick profile names: `<job>-ssh` for the SSH login, `<job>-db` for the remote DB user.
2. List what exists (names only):
   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/vault.ps1" list
   ```
3. To store one, ask permission first, then run it. A password dialog opens on the user's screen: tell them to type the secret there.
   ```
   powershell.exe -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/vault.ps1" set <profile>
   ```
   If no dialog appears, ask the user to run the same command in their own terminal.
4. To delete one (e.g. after the job, if the user wants): same command with `remove <profile>`.

## Rules

- Never run `vault.ps1 get`, never open/read/grep the vault folder, never ask the user to paste a password into the chat.
- If a script fails with `Permission denied`, the stored secret is wrong: ask the user to `set` it again.
