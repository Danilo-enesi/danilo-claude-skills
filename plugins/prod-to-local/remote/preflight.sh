# Runs ON THE SERVER via `bash -s`. Read-only: prints facts, writes nothing.
# Args: [site-path]
site=${1:-}
echo "user=$(id -un) host=$(hostname) home=$HOME"
for t in tar gzip sha256sum mysqldump mysql nice du df; do
  command -v "$t" >/dev/null 2>&1 && echo "tool $t: ok" || echo "tool $t: MISSING"
done
df -Pk "$HOME" | awk 'NR==2 {printf "free_home_mb=%d\n", $4/1024}'
if [ -z "$site" ]; then
  echo "home listing:"; ls -la "$HOME" | head -40
elif [ -d "$site" ]; then
  nice -n 19 du -sk "$site" | awk '{printf "site_mb=%d\n", $1/1024}'
  echo "site_files=$(nice -n 19 find "$site" -type f | wc -l)"
  echo "site top level:"; ls -A "$site" | head -60
else
  echo "site: NOT FOUND ($site)"
fi
ls -1d "$HOME"/.prod-to-local-* 2>/dev/null | sed 's/^/leftover: /'
exit 0
