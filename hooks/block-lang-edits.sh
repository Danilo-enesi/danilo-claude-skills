#!/usr/bin/env bash
# Blocca Edit/Write su resources/lang/** nei progetti Master che li rigenerano con ln_upd.php.
path=$(grep -oE '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/^"file_path"[[:space:]]*:[[:space:]]*"//; s/"$//; s#\\#/#g')
case "$path" in
  */resources/lang/*) root="${path%%/resources/lang/*}" ;;
  *) exit 0 ;;
esac
# Laravel senza ln_upd.php: resources/lang si modifica a mano, non bloccare.
[ -f "$root/app/Console/Commands/Utility/ln_upd.php" ] || exit 0
echo "BLOCCATO: i file in resources/lang sono generati dal DB da \"php artisan ln:upd\" e ogni modifica a mano va persa. Aggiungi/modifica la chiave in $root/app/Console/Commands/Utility/ln_upd.php e poi esegui \"php artisan ln:upd\" da $root." >&2
exit 2
