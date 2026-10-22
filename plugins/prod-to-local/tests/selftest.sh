#!/usr/bin/env bash
# Offline self-test: fake ssh/scp/mysqldump run the remote scripts locally against a fake server $HOME.
# Touches only a temp folder and one vault profile (selftest-*), both removed at the end.
set -euo pipefail
PLUGIN="$(cd "$(dirname "$0")/.." && pwd)"
S="$PLUGIN/scripts"
T=$(mktemp -d); trap 'rm -rf "$T"; vault remove "$P" >/dev/null 2>&1 || true' EXIT
P="selftest-$RANDOM"
vault() { powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "$(cygpath -w "$S/vault.ps1")" "$@"; }
pass() { echo "PASS: $*"; }
fail() { echo "FAIL: $*"; exit 1; }

export FAKE_HOME="$T/server-home"; mkdir -p "$FAKE_HOME/www/sub" "$T/bin" "$T/local"
echo '<?php echo 1;' > "$FAKE_HOME/www/index.php"; echo x > "$FAKE_HOME/www/sub/a.txt"; echo big > "$FAKE_HOME/www/sub/skip.log"

# fake ssh: drop options and user@host, run the remote command with bash in the fake server home.
cat > "$T/bin/ssh" <<'EOF'
#!/usr/bin/env bash
while [ $# -gt 0 ]; do case "$1" in -o|-p) shift 2 ;; -*) shift ;; *@*) shift; break ;; *) break ;; esac; done
cd "$FAKE_HOME" && HOME="$FAKE_HOME" exec bash -c "$*"
EOF
cat > "$T/bin/scp" <<'EOF'
#!/usr/bin/env bash
while [ $# -gt 2 ]; do shift; done
cp "$FAKE_HOME/${1#*:}" "$2"
EOF
cat > "$T/bin/mysql" <<'EOF'
#!/usr/bin/env bash
# data bytes, routines, views on the "server" (the fixture has 2 routines, 1 view)
printf '1048576\t%s\t1\n' "${FAKE_ROUTINES:-2}"
EOF
cat > "$T/bin/mysqldump" <<'EOF'
#!/usr/bin/env bash
[ "$MYSQL_PWD" = "s3cr3t-pw" ] || { echo "bad password" >&2; exit 2; }
cat "$FIXTURE"
EOF
chmod +x "$T/bin/"*
export PATH="$T/bin:$PATH" FIXTURE="$PLUGIN/tests/fixtures/mysqldump-5.7.sql"

# vault: create a profile without the dialog (same DPAPI format as `set`), then check has/get/list.
powershell.exe -NoProfile -NonInteractive -Command "New-Item -ItemType Directory -Force (Join-Path \$HOME '.prod-to-local\vault') | Out-Null; ConvertTo-SecureString 's3cr3t-pw' -AsPlainText -Force | ConvertFrom-SecureString | Set-Content (Join-Path \$HOME '.prod-to-local\vault\\$P.cred') -Encoding ascii"
vault has "$P" >/dev/null || fail "vault has"
[ "$(vault get "$P" | od -c | head -1)" = "$(printf 's3cr3t-pw\n' | od -c | head -1)" ] || fail "vault get must end with LF only"
vault list | grep -qx "$P" || fail "vault list"
pass vault

common=(--user u --host example.test --port 2222 --profile "$P")

# pull-code happy path, with an exclude
bash "$S/pull-code.sh" --job st1 "${common[@]}" --site "$FAKE_HOME/www" --dest "$T/local/site" --exclude ./sub/skip.log >/dev/null
[ -f "$T/local/site/index.php" ] && [ -f "$T/local/site/sub/a.txt" ] || fail "files not extracted"
[ ! -e "$T/local/site/sub/skip.log" ] || fail "exclude ignored"
! ls "$FAKE_HOME"/.prod-to-local-* >/dev/null 2>&1 || fail "server temp file left behind"
pass pull-code

# pull-db happy path, same job
bash "$S/pull-db.sh" --job st1 "${common[@]}" --db-profile "$P" --db-user dbu --db-name shop_db --out "$T/local/shop.sql.gz" >/dev/null
d=$(gzip -dc "$T/local/shop.sql.gz")
grep -q 'CREATE TABLE `b`' <<<"$d" || fail "dump content"
[ "$(head -n 1 <<<"$d")" = 'SET FOREIGN_KEY_CHECKS=0;' ] && [ "$(tail -n 1 <<<"$d")" = 'SET FOREIGN_KEY_CHECKS=1;' ] || fail "FK wrapper"
! grep -q 'DEFINER=' <<<"$d" || fail "DEFINER left"
grep -q 'FUNCTION `f`' <<<"$d" && grep -q 'PROCEDURE `p`' <<<"$d" && grep -q 'VIEW `v`' <<<"$d" && grep -q 'TRIGGER t' <<<"$d" || fail "routines/views/triggers missing"
! ls "$FAKE_HOME"/.prod-to-local-* >/dev/null 2>&1 || fail "server dump left behind"
pass pull-db

# a dump missing a routine the server has must fail (and roll back)
if FAKE_ROUTINES=3 bash "$S/pull-db.sh" --job st5 "${common[@]}" --db-profile "$P" --db-user dbu --db-name shop_db --out "$T/local/miss.sql.gz" >/dev/null 2>&1; then fail "missing routine accepted"; fi
[ ! -e "$T/local/miss.sql.gz" ] || fail "incomplete dump kept"
pass routine-count-check

# a failing step rolls back the WHOLE job: wrong DB password -> code folder and dump of job st1 are gone too
rm "$T/local/shop.sql.gz"
powershell.exe -NoProfile -NonInteractive -Command "ConvertTo-SecureString 'wrong' -AsPlainText -Force | ConvertFrom-SecureString | Set-Content (Join-Path \$HOME '.prod-to-local\vault\\$P.cred') -Encoding ascii"
if bash "$S/pull-db.sh" --job st1 "${common[@]}" --db-profile "$P" --db-user dbu --db-name shop_db --out "$T/local/shop.sql.gz" >/dev/null 2>&1; then fail "bad password accepted"; fi
[ ! -e "$T/local/site" ] || fail "code folder not rolled back"
[ ! -e "$T/local/shop.sql.gz" ] || fail "partial dump not rolled back"
! ls "$FAKE_HOME"/.prod-to-local-* >/dev/null 2>&1 || fail "server temp file left after failure"
[ ! -e "$HOME/.prod-to-local/jobs/st1.ledger" ] || fail "ledger not cleared"
pass rollback-on-failure

# never overwrite an existing destination
mkdir "$T/local/exists"
if bash "$S/pull-code.sh" --job st2 "${common[@]}" --site "$FAKE_HOME/www" --dest "$T/local/exists" >/dev/null 2>&1; then fail "overwrote existing dest"; fi
[ -d "$T/local/exists" ] || fail "existing dest was deleted"
pass no-overwrite

# missing site fails cleanly
if bash "$S/pull-code.sh" --job st3 "${common[@]}" --site "$FAKE_HOME/nope" --dest "$T/local/s3" >/dev/null 2>&1; then fail "missing site accepted"; fi
[ ! -e "$T/local/s3" ] || fail "dest created for missing site"
pass missing-site

# commit (--forget) keeps files and drops the marker
bash "$S/pull-code.sh" --job st4 "${common[@]}" --site "$FAKE_HOME/www" --dest "$T/local/s4" >/dev/null
bash "$S/rollback.sh" --job st4 --forget >/dev/null
[ -f "$T/local/s4/index.php" ] && [ ! -e "$T/local/s4/.prod-to-local.job" ] || fail "forget"
pass forget

# hook
H="$PLUGIN/hooks/guard-vault.sh"
echo '{"tool_name":"Bash","tool_input":{"command":"powershell -File x/vault.ps1 get foo"}}' | bash "$H" 2>/dev/null && fail "hook let vault get through"
echo '{"tool_name":"Read","tool_input":{"file_path":"C:\\Users\\x\\.prod-to-local\\vault\\a.cred"}}' | bash "$H" 2>/dev/null && fail "hook let vault read through"
echo '{"tool_name":"Bash","tool_input":{"command":"bash scripts/pull-code.sh --job x"}}' | bash "$H" | grep -q '"ask"' || fail "hook did not ask"
echo '{"tool_name":"Bash","tool_input":{"command":"ls"}}' | bash "$H" | grep -q . && fail "hook noisy on unrelated command"
echo '{"tool_name":"Edit","tool_input":{"file_path":"skills/x/SKILL.md","new_string":"askpass.sh"}}' | bash "$H" || fail "hook blocked editing docs"
pass hook

echo "ALL PASSED"
