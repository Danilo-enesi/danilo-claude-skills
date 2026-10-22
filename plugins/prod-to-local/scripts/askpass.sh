#!/usr/bin/env bash
# SSH_ASKPASS helper: ssh runs it to get the password, so the secret goes from the vault straight into ssh.
# Anything else ssh asks (e.g. an unknown host key) must not get the password as its answer.
case "${1:-}" in *assword*) ;; *) exit 1 ;; esac
exec powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$(cygpath -w "$(dirname "$0")/vault.ps1")" get "$PROD_TO_LOCAL_PROFILE"
