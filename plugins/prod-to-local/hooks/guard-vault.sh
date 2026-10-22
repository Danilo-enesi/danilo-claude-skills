#!/usr/bin/env bash
# PreToolUse guard for the prod-to-local vault.
#  - blocks any tool call that touches the vault folder, calls `vault.ps1 get` or runs askpass.sh: Claude never sees a secret.
#  - forces a user permission prompt (even in auto mode) for every script that uses the vault or talks to the server.
input=$(cat)

block() { echo "BLOCKED by prod-to-local: $1. Secrets are only read inside the plugin scripts." >&2; exit 2; }

grep -qiE '\.prod-to-local[/\\]+vault' <<<"$input" && block "direct access to the vault folder"
# Editing the plugin's own files may mention these names; only shell commands are checked from here on.
grep -qE '"tool_name"[[:space:]]*:[[:space:]]*"(Bash|PowerShell)"' <<<"$input" || exit 0
grep -qiE 'askpass\.sh' <<<"$input" && block "direct call to askpass.sh"
grep -qiE 'vault\.ps1[^a-z]+get\b' <<<"$input" && block "vault.ps1 get"

if grep -qE '(preflight|pull-code|pull-db|rollback)\.sh|vault\.ps1' <<<"$input"; then
  cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"ask","permissionDecisionReason":"prod-to-local: this command uses the credential vault and/or the production server. Approve only if Claude explained what it does."}}
JSON
fi
exit 0
