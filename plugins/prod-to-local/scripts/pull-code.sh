#!/usr/bin/env bash
# Copies the site files from the server into a NEW local folder. On any failure the whole job is rolled back.
# Usage: pull-code.sh --job J --user U --host H --port P --profile SSH_PROFILE --site PATH [--dest DIR] [--exclude PATTERN]...
source "$(dirname "$0")/lib.sh"

excludes=()
while [ $# -gt 0 ]; do
  case "$1" in
    --job) job=$2; shift 2 ;; --user) user=$2; shift 2 ;; --host) host=$2; shift 2 ;; --port) port=$2; shift 2 ;;
    --profile) profile=$2; shift 2 ;; --site) site=$2; shift 2 ;; --dest) dest=$2; shift 2 ;;
    --exclude) excludes+=("$2"); shift 2 ;;
    *) die "unknown option $1" ;;
  esac
done
ssh_target "${user:?--user}" "${host:?--host}" "${port:?--port}" "${profile:?--profile}"
: "${site:?--site}"
dest=${dest:-$DEFAULT_PARENT/${job:?--job}}
[ -e "$dest" ] && die "$dest already exists: choose another --dest (never overwrite)"
[ -d "$(dirname "$dest")" ] || die "parent folder $(dirname "$dest") does not exist"
vault_require "$profile"
job_start "${job:?--job}"

name=$(remote_name .tgz)
archive="$STATE_DIR/tmp/$name"

info "1/5 packing $site on the server into \$HOME/$name"
ledger_add remote-file "$user" "$host" "$port" "$profile" "$name"
out=$(remote pack-code.sh "$site" "$name" ${excludes[@]+"${excludes[@]}"})
sha=$(sed -n 's/^SHA256=//p' <<<"$out"); bytes=$(sed -n 's/^BYTES=//p' <<<"$out")
[ -n "$sha" ] || die "server did not report a checksum"
echo "archive: $((bytes / 1048576)) MB"

info "2/5 downloading"
ledger_add local-file "$archive"
fetch "$name" "$archive"

info "3/5 verifying checksum"
[ "$(sha256sum "$archive" | cut -d' ' -f1)" = "$sha" ] || die "checksum mismatch: download corrupted"

info "4/5 removing the archive from the server"
remote cleanup.sh "$name"
ledger_del remote-file "$user" "$host" "$port" "$profile" "$name"

info "5/5 extracting into $dest"
mkdir "$dest"
echo "$job" > "$dest/.prod-to-local.job"   # rollback deletes $dest only if this marker matches
ledger_add local-dir "$dest"
tar -xzf "$archive" -C "$dest"
rm -f "$archive"; ledger_del local-file "$archive"

echo "DONE: $(find "$dest" -type f | wc -l) files, $(du -sh "$dest" | cut -f1) in $dest"
