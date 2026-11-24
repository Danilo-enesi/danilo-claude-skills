---
description: Crea lo scaffolding del front Master Laravel Enesi (Views + assets del tema Main) dai template del plugin e lo verifica
argument-hint: "[root del progetto]"
---

## Regola d'oro

Crea solo ciò che manca. **Non sovrascrivere mai** un file esistente.

## Procedura

1. Root del progetto: `$ARGUMENTS`, altrimenti la root git della cartella corrente.
2. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" <root>`.
   - `NEW` = creato, `SKIP` = esisteva già, `TODO` = da fare a mano.
   - Se esce `STOP`, fermati e riporta il motivo.
3. Per ogni `SKIP` di `layouts/main.blade.php`, `partials/base/head.blade.php` e `partials/base/scripts.blade.php`: confronta il file con il template in `${CLAUDE_PLUGIN_ROOT}/templates/views/` e **proponi** le differenze. Non applicarle senza conferma.
4. Per ogni `TODO`: spiega cosa va fatto (es. copiare Beers in `assets/common/beers/`).
5. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-all.sh" <root>`.
6. Rotte e controller non li crea lo script: segui la skill `front-routes` (`PagesController@home` nei gruppi lingua, gruppo `root.` + `PagesController@index` per il redirect alla lingua preferita); la home rende `view('pages.home.index')`.
7. Rispondi con una tabella `file → NEW/SKIP/TODO` e l'elenco dei `FAIL` rimasti, ognuno con la sua regola (`rules/<id>.md`).
