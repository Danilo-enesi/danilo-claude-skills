---
name: prod-pull-db
author: Danilo-enesi
description: Dump a production MySQL database on the server WITHOUT table locks (tables, views, functions, procedures, triggers) and download it as a NEW local .sql.gz (default C:\devProjects\<db-name>.sql.gz), cleaned for a local import - foreign key checks disabled, DEFINER user@host removed - and verified; all-or-nothing. Use when the user wants the project's database copied to this PC. Does not import it anywhere.
---

# prod-pull-db

**Rule:** the live DB is only read, never locked; the password only travels through stdin.

## What the script does

1. On the server: counts routines/views, checks free space, then `nice mysqldump --single-transaction --skip-lock-tables --quick --no-tablespaces --hex-blob --triggers --routines | gzip` into `$HOME/.prod-to-local-<job>-<time>.sql.gz`. Password via stdin -> `MYSQL_PWD`, never on the command line.
2. Downloads it, checks the SHA-256 and the `-- Dump completed` line, deletes it from the server.
3. Cleans it locally (`scripts/clean-dump.sh`, data rows untouched):
   - `SET FOREIGN_KEY_CHECKS=0;` first line, `=1;` last line: tables import in any order.
   - every `DEFINER=user@host` removed from views, routines and triggers: they import as the local user instead of failing on a server user that does not exist locally.
4. Checks the result: FK header, no `DEFINER=` left, routines and views count equal to the server's.
5. Prints `REVIEW:` lines: `localhost`, `127.0.0.1`, the server host or `` `<db>`. `` hardcoded inside view/routine/trigger bodies. Those are **not** rewritten.

Any failure: the whole job is rolled back, including a code folder pulled earlier in the same job.

## Steps

1. You need the DB name and DB user. If you do not have them, ask the user; do not read them from the server's config files.
2. Make sure vault profile `<job>-db` exists (`prod-vault`).
3. Ask the charset of the tables (`utf8` default; `latin1` for old sites that store UTF-8 bytes in latin1 columns, if the user knows).
4. Tell the user what will run and ask permission. Then:
   ```
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/pull-db.sh" --job <job> --user <user> --host <host> --port <port> --profile <job>-ssh --db-profile <job>-db --db-user <dbuser> --db-name <dbname> [--charset utf8] [--out /c/devProjects/<dbname>.sql.gz]
   ```
5. Report the `DONE:` line (file, size, tables, routines, views) and show every `REVIEW:` line: the user decides whether those values must change for the local copy.

## Rules

- `routines: server has N, dump has M`: the DB user cannot read some routine bodies. Tell the user; do not retry with another user on your own.
- MyISAM tables are dumped without locks, so they may be slightly inconsistent on a busy site: say so if the user needs an exact snapshot.
- `cannot connect to MySQL`: wrong DB user/password or host. Ask; do not guess.
