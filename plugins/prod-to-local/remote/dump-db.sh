# Runs ON THE SERVER via `bash -s`, with the DB password already in MYSQL_PWD (never on the command line).
# Only write: one gzip dump $HOME/<name>, removed on failure. No table locks on the live DB.
# Args: <db-host> <db-user> <db-name> <charset> <name>
set -u
db_host=$1 db_user=$2 db_name=$3 charset=$4 name=$5
out="$HOME/$name"
fail() { echo "REMOTE ERROR: $*" >&2; rm -f -- "$out"; exit 1; }
case "$name" in .prod-to-local-*.sql.gz) ;; *) echo "REMOTE ERROR: bad dump name" >&2; exit 1 ;; esac
[[ "$db_name" =~ ^[A-Za-z0-9_]+$ ]] || { echo "REMOTE ERROR: bad db name" >&2; exit 1; }
[ -e "$out" ] && { echo "REMOTE ERROR: $out already exists" >&2; exit 1; }

# Data size (for the space check) + how many routines/views exist (the local side checks the dump has them all).
stats=$(mysql -N -h "$db_host" -u "$db_user" -e "SELECT
  (SELECT COALESCE(SUM(data_length+index_length),0) FROM information_schema.tables WHERE table_schema='$db_name'),
  (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='$db_name'),
  (SELECT COUNT(*) FROM information_schema.views WHERE table_schema='$db_name')") || { echo "REMOTE ERROR: cannot connect to MySQL as $db_user" >&2; exit 1; }
read -r size_b n_routines n_views <<<"$stats"
free_kb=$(df -Pk "$HOME" | awk 'NR==2 {print $4}')
# The gzip dump is far smaller than the data; requiring the full data size + 100 MB is a safe upper bound.
[ "$free_kb" -gt $((size_b / 1024 + 102400)) ] || { echo "REMOTE ERROR: not enough space in \$HOME (data ~$((size_b/1048576)) MB, free $((free_kb/1024)) MB)" >&2; exit 1; }

nice -n 19 mysqldump --single-transaction --quick --skip-lock-tables --no-tablespaces --hex-blob --triggers --routines \
  --default-character-set="$charset" -h "$db_host" -u "$db_user" "$db_name" | nice -n 19 gzip > "$out"
codes=("${PIPESTATUS[@]}")
[ "${codes[0]}" -eq 0 ] || fail "mysqldump exit ${codes[0]}"
[ "${codes[1]}" -eq 0 ] || fail "gzip exit ${codes[1]}"
echo "SHA256=$(sha256sum "$out" | cut -d' ' -f1)"
echo "BYTES=$(wc -c < "$out")"
echo "DATA_MB=$((size_b / 1048576))"
echo "ROUTINES=$n_routines"
echo "VIEWS=$n_views"
