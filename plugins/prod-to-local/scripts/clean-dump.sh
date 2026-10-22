#!/usr/bin/env bash
# Makes a raw mysqldump importable on another server: foreign key checks off for the whole import,
# DEFINER=`user`@`host` removed from views, routines and triggers (the importing user becomes the definer).
# Data rows (INSERT lines) are never touched.
# Usage: clean-dump.sh <raw.sql.gz> <out.sql.gz>
set -euo pipefail
in=$1 out=$2
[ -e "$out" ] && { echo "ERROR: $out already exists" >&2; exit 1; }
q='`[^`]*`|'"'[^']*'"'|[A-Za-z0-9_.%-]+'
{
  echo 'SET FOREIGN_KEY_CHECKS=0;'
  gzip -dc "$in" | sed -E "/^INSERT INTO /!s/DEFINER=($q)@($q)//g"
  echo 'SET FOREIGN_KEY_CHECKS=1;'
} | gzip > "$out"
