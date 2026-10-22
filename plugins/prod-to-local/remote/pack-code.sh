# Runs ON THE SERVER via `bash -s`. Only write: one archive $HOME/<name>, removed on failure.
# Args: <site-path> <name> [exclude...]
set -u
site=$1 name=$2; shift 2
out="$HOME/$name"
fail() { echo "REMOTE ERROR: $*" >&2; rm -f -- "$out"; exit 1; }
case "$name" in .prod-to-local-*.tgz) ;; *) echo "REMOTE ERROR: bad archive name" >&2; exit 1 ;; esac
[ -d "$site" ] || { echo "REMOTE ERROR: site not found: $site" >&2; exit 1; }
[ -e "$out" ] && { echo "REMOTE ERROR: $out already exists" >&2; exit 1; }

need_kb=$(nice -n 19 du -sk "$site" | cut -f1)
free_kb=$(df -Pk "$HOME" | awk 'NR==2 {print $4}')
# The archive is at most the site size; keep 100 MB extra so the server never fills up.
[ "$free_kb" -gt $((need_kb + 102400)) ] || { echo "REMOTE ERROR: not enough space in \$HOME (need ~$((need_kb/1024)) MB + 100 MB, free $((free_kb/1024)) MB)" >&2; exit 1; }

excludes=()
for e in "$@"; do excludes+=("--exclude=$e"); done
# ${a[@]+...}: an empty array under set -u breaks on bash < 4.4 (old servers).
nice -n 19 tar -czf "$out" ${excludes[@]+"${excludes[@]}"} -C "$site" .
rc=$?
# GNU tar exit 1 = some files changed while being read (live site): archive is still valid.
[ $rc -le 1 ] || fail "tar exit $rc"
[ $rc -eq 1 ] && echo "WARNING: some files changed while archiving (live site)" >&2
echo "SHA256=$(sha256sum "$out" | cut -d' ' -f1)"
echo "BYTES=$(wc -c < "$out")"
