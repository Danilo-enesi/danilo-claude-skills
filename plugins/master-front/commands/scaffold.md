---
description: Scrive lo scaffolding del front Master Laravel Enesi dai template del plugin, sovrascrivendo ciò che è diverso; prima fa scegliere le cartelle da installare e chiede se fare un backup
argument-hint: "[root del progetto]"
---

## Regola d'oro

Lo scaffold **sovrascrive**. Prima l'utente sceglie cosa installare e se fare un backup, poi si scrive.

## Procedura

1. Root del progetto: `$ARGUMENTS`, altrimenti la root git della cartella corrente.
2. **Anteprima**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" --dry-run <root>`. Se esce `STOP`, fermati e riporta il motivo. Mostra il riepilogo (quanti `NEW`, `OVER`, `DEL`) e i file `OVER`/`DEL` per nome.
3. **Cartelle da integrare**: chiedi con `AskUserQuestion` (`multiSelect: true`), tutte proposte come scelta di default. La `description` di ogni opzione dice, dal dry-run, cosa verrà **sovrascritto o eliminato** in quella cartella, con le righe del file del progetto:
   - `views` (tutte le Views: layouts, partials, components, pages, mail; toglie `Views/base/`) — es. «⚠ sovrascrive layouts/main.blade.php (180 righe), partials/header.blade.php (95 righe); elimina Views/base/ (4 file)»
   - `assets/main/css` — es. «⚠ sovrascrive main.css (2300 righe)»
   - `assets/main/js` — es. «⚠ sovrascrive main.js (1000 righe)»
   - `assets/mail`

   Se in una cartella non c'è nulla da sovrascrivere, scrivi «solo file nuovi». Se un file da sovrascrivere ha molte più righe del template (lavoro vero del progetto), mettilo in evidenza e suggerisci di togliere quella cartella.
   Beers (`assets/common/beers/`, solo se il progetto non ce l'ha: se esiste non si tocca mai, è adattata al progetto), le classi dei componenti (`private/front/Main/Components/`) e le cartelle vuote di `assets/main/` (lib, icons, images, videos, documents) si installano sempre: dillo nella domanda.
4. **Backup**: chiedi con `AskUserQuestion`, nominando i file che verranno sovrascritti o eliminati nelle cartelle scelte:
   - «Sì, fai il backup» (consigliato): copia ciò che sostituisce in `.scaffold-backup/<data>/`
   - «No, senza backup»
5. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" [--backup] --only <gruppi scelti, separati da virgola> <root>`.
6. Con backup: se `.scaffold-backup/` non è in `.gitignore`, dillo: va tolta dopo il controllo, non committata.
7. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-all.sh" <root>`.
8. Rotte e controller non li crea lo script: segui la skill `front-routes` (`PagesController@home` nei gruppi lingua, gruppo `root.` + `PagesController@index` per il redirect alla lingua preferita); la home rende `view('pages.home.index')`. Se nel backup c'erano viste referenziate dai controller (es. `base.*`), elenca i `view('...')` da aggiornare.
9. Rispondi con una tabella `file → NEW/OVER/SAME/SKIP/DEL/TODO`, il percorso del backup (se fatto) e i `FAIL` rimasti, ognuno con la sua regola (`rules/<id>.md`).
