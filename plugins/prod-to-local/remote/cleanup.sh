# Runs ON THE SERVER via `bash -s`. Deletes one temp file created by this plugin, and nothing else.
# Args: <name>
name=$1
case "$name" in
  .prod-to-local-*.tgz | .prod-to-local-*.sql.gz) ;;
  *) echo "REMOTE ERROR: refusing to delete '$name'" >&2; exit 1 ;;
esac
case "$name" in */*) echo "REMOTE ERROR: refusing path '$name'" >&2; exit 1 ;; esac
rm -f -- "$HOME/$name"
[ ! -e "$HOME/$name" ] && echo "removed \$HOME/$name"
