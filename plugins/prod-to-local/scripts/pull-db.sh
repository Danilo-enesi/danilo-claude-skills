#!/usr/bin/env bash
# Dumps the production database on the server (no locks, with views/routines/triggers) and downloads it as a NEW
# local .sql.gz, cleaned for a local import (FK checks off, no DEFINER). Does not import it.
# Usage: pull-db.sh --job J --user U --host H --port P --profile SSH_PROFILE --db-profile DB_PROFILE --db-user DBU --db-name DBN
#                   [--db-host localhost] [--charset utf8] [--out FILE]
source "$(dirname "$0")/lib.sh"

db_host=localhost charset=utf8
while [ $# -gt 0 ]; do
  case "$1" in
    --job) job=$2; shift 2 ;; --user) user=$2; shift 2 ;; --host) host=$2; shift 2 ;; --port) port=$2; shift 2 ;;
    --profile) profile=$2; shift 2 ;; --db-profile) db_profile=$2; shift 2 ;;
    --db-user) db_user=$2; shift 2 ;; --db-name) db_name=$2; shift 2 ;; --db-host) db_host=$2; shift 2 ;;
    --charset) charset=$2; shift 2 ;; --out) out=$2; shift 2 ;;
    *) die "unknown option $1" ;;
  esac
done
ssh_target "${user:?--user}" "${host:?--host}" "${port:?--port}" "${profile:?--profile}"
check_name db-profile "${db_profile:?--db-profile}"; check_name db-user "${db_user:?--db-user}"; check_name db-host "$db_host"
[[ "${db_name:?--db-name}" =~ ^[A-Za-z0-9_]+$ ]] || die "invalid --db-name"
[[ "$charset" =~ ^[a-z0-9]+$ ]] || die "invalid --charset"
out=${out:-$DEFAULT_PARENT/$db_name.sql.gz}
[ -e "$out" ] && die "$out already exists: choose another --out (never overwrite)"
[ -d "$(dirname "$out")" ] || die "parent folder $(dirname "$out") does not exist"
vault_require "$profile"; vault_require "$db_profile"
job_start "${job:?--job}"

name=$(remote_name .sql.gz)
raw="$STATE_DIR/tmp/$name"
schema="$STATE_DIR/tmp/$name.schema.sql"

info "1/6 dumping $db_name on the server into \$HOME/$name (single transaction, no locks)"
ledger_add remote-file "$user" "$host" "$port" "$profile" "$name"
res=$(remote_with_secret "$db_profile" dump-db.sh "$db_host" "$db_user" "$db_name" "$charset" "$name")
val() { sed -n "s/^$1=//p" <<<"$res"; }
sha=$(val SHA256); bytes=$(val BYTES); n_routines=$(val ROUTINES); n_views=$(val VIEWS)
[ -n "$sha" ] || die "server did not report a checksum"
echo "dump: $((bytes / 1048576)) MB gzip (data ~$(val DATA_MB) MB), routines: $n_routines, views: $n_views"

info "2/6 downloading"
ledger_add local-file "$raw"
fetch "$name" "$raw"

info "3/6 verifying checksum and dump completeness"
[ "$(sha256sum "$raw" | cut -d' ' -f1)" = "$sha" ] || die "checksum mismatch: download corrupted"
gzip -dc "$raw" | tail -n 1 | grep -q '^-- Dump completed' || die "dump is truncated (no 'Dump completed' line)"

info "4/6 removing the dump from the server"
remote cleanup.sh "$name"
ledger_del remote-file "$user" "$host" "$port" "$profile" "$name"

info "5/6 cleaning for local import into $out (FK checks off, DEFINER removed)"
ledger_add local-file "$out"
bash "$SCRIPTS_DIR/clean-dump.sh" "$raw" "$out"
rm -f "$raw"; ledger_del local-file "$raw"

info "6/6 checking the cleaned dump"
ledger_add local-file "$schema"
gzip -dc "$out" | grep -v '^INSERT INTO ' > "$schema" || true
[ "$(head -n 1 "$schema")" = 'SET FOREIGN_KEY_CHECKS=0;' ] || die "FK header missing"
! grep -q 'DEFINER=' "$schema" || die "DEFINER clauses left in the dump"
got_r=$(grep -cE '^(/\*!50003 )?CREATE.*(FUNCTION|PROCEDURE) `' "$schema" || true)
got_v=$(grep -cE '^/\*!50001 VIEW `' "$schema" || true)
[ "$got_r" -eq "$n_routines" ] || die "routines: server has $n_routines, dump has $got_r (DB user lacks privileges to read them?)"
[ "$got_v" -eq "$n_views" ] || die "views: server has $n_views, dump has $got_v"
# Hardcoded hosts/DB names inside view/routine/trigger bodies are not rewritten: the user decides.
grep -nE "localhost|127\.0\.0\.1|\`$db_name\`\.|$host" "$schema" | grep -vE '^[0-9]+:--' | head -n 20 | sed 's/^/REVIEW: /' || true
rm -f "$schema"; ledger_del local-file "$schema"

echo "DONE: $out ($(du -h "$out" | cut -f1)), tables: $(gzip -dc "$out" | grep -c '^CREATE TABLE'), routines: $got_r, views: $got_v"
