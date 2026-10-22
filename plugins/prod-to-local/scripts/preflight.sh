#!/usr/bin/env bash
# Read-only look at the server: host key, login, tools, free space, site size. Writes nothing anywhere.
# Usage: preflight.sh --user U --host H --port P --profile SSH_PROFILE [--site PATH] [--trust-host-key]
source "$(dirname "$0")/lib.sh"

site="" trust=no
while [ $# -gt 0 ]; do
  case "$1" in
    --user) user=$2; shift 2 ;; --host) host=$2; shift 2 ;; --port) port=$2; shift 2 ;;
    --profile) profile=$2; shift 2 ;; --site) site=$2; shift 2 ;;
    --trust-host-key) trust=yes; shift ;;
    *) die "unknown option $1" ;;
  esac
done
ssh_target "${user:?--user}" "${host:?--host}" "${port:?--port}" "${profile:?--profile}"

known="[$host]:$port"; [ "$port" = 22 ] && known=$host
if ! ssh-keygen -F "$known" >/dev/null; then
  keys=$(ssh-keyscan -T 15 -p "$port" "$host" 2>/dev/null) || true
  [ -n "$keys" ] || die "cannot reach $host:$port"
  if [ "$trust" = no ]; then
    echo "UNKNOWN HOST KEY for [$host]:$port. Fingerprints:"
    ssh-keygen -lf - <<<"$keys"
    echo "Show these to the user. Only if they confirm, rerun with --trust-host-key."
    exit 3
  fi
  mkdir -p ~/.ssh && echo "$keys" >> ~/.ssh/known_hosts
  echo "host key for [$host]:$port added to ~/.ssh/known_hosts"
fi

vault_require "$profile"
info "server facts (read-only)"
remote preflight.sh "$site"
