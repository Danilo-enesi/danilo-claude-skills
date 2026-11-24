---
description: Scrive lo scaffolding del front Master Laravel Enesi dai template del plugin, sovrascrivendo ciò che è diverso; prima fa scegliere le cartelle da installare e chiede se fare un backup
argument-hint: "[root del progetto]"
---

## Regola d'oro

Lo scaffold **sovrascrive**. Prima l'utente sceglie cosa installare e se fare un backup, poi si scrive.

## Procedura

1. Root del progetto: `$ARGUMENTS`, altrimenti la root git della cartella corrente.
2. **Anteprima**: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" --dry-run <root>`. Se esce `STOP`, fermati e riporta il motivo. Mostra il riepilogo (quanti `NEW`, `OVER`, `DEL`) e i file `OVER`/`DEL` per nome.
   Controlla anche il canonical: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-meta.sh" <root> | grep -i 'canonical come'`. Se esce `FAIL ... come <meta>`, **confermalo con il render vero** prima di proporre la riparazione (il controllo è statico e può sbagliare su uno stile di codice nuovo): `php artisan tinker --execute="Meta::set('canonical', 'https://esempio.it/a'); echo Meta::render();" | grep -i canonical` dalla cartella di `artisan`. Se esce `<link rel="canonical"`, è un falso positivo: niente voce 14, e segnalalo nel riepilogo finale. Se non c'è PHP, fidati del controllo.
   **DESIGN.md**: se nella root del progetto non esiste, raccogli **adesso**, prima che lo scaffold sovrascriva qualcosa, il design che il front ha già:
   - colori: variabili CSS (`:root { --... }`), colori ricorrenti in `assets/main/css/*.css` (soprattutto il colore principale di bottoni e link);
   - tipografia: font in `partials/base/head.blade.php` (`Meta::googleFonts(...)`, `@font-face`), `font-family`/`font-size` di `body` e dei titoli;
   - layout: larghezza del container, breakpoint di `responsive.css`, spaziature ricorrenti; `border-radius` ricorrenti (rounded).
   Prendi solo valori **che ci sono davvero** (niente valori inventati né quelli dei template del plugin). Se il front non ha nulla di suo, DESIGN.md resta vuoto.
3. **Cartelle da integrare**: mostra la lista; **marcate di default** `[x]` le cartelle 1-8, non marcate `[ ]` le altre cartelle di `assets/main/` (9-13); accanto a ognuna, dal dry-run, cosa verrà sovrascritto o eliminato, con le righe del file del progetto (o «solo file nuovi»):
   ```
   Cartelle da installare ([x] = installata):
   [x] 1  views/layouts      ⚠ sovrascrive main.blade.php (180 righe → 24); elimina Views/base/ (4 file)
   [x] 2  views/partials     ⚠ sovrascrive header.blade.php (95 righe → 8)
   [x] 3  views/components   solo file nuovi
   [x] 4  views/pages        solo file nuovi
   [x] 5  views/mail         solo file nuovi
   [x] 6  assets/main/css    ⚠ sovrascrive main.css (2300 righe → 30)
   [x] 7  assets/main/js     ⚠ sovrascrive main.js (1000 righe → 21)
   [x] 8  assets/mail        solo file nuovi
   [ ] 9  assets/main/lib        solo file nuovi
   [ ] 10 assets/main/icons      già presente
   [ ] 11 assets/main/images     solo file nuovi (images/defaults, images/icons)
   [ ] 12 assets/main/videos     solo file nuovi
   [ ] 13 assets/main/documents  solo file nuovi
   [x] 14 ripara Meta            ⚠ il core stampa il canonical come <meta>: override di render_property in private/master/Foundation/Meta.php
   Sempre installati: Beers (assets/common/beers/, solo se manca: se esiste non si tocca mai, il layout la carica),
   le classi dei componenti (private/front/Main/Components/) e DESIGN.md nella root (solo se manca, compilato dal front;
   obbligatorio, `rules/design-md.md`; se il progetto ha un CLAUDE.md, gli si aggiunge la sezione per usarlo nel front e tenerlo aggiornato).
   ```
   Se un file da sovrascrivere ha molte più righe del template (lavoro vero del progetto), mettilo in evidenza. Poi chiedi con `AskUserQuestion` (scelta singola):
   - «Installa le marcate» (consigliato se non c'è nulla di grosso da sovrascrivere)
   - «Le marcate + tutte le cartelle di assets» → aggiunge 9-13
   - «Togli quelle con ⚠» → restano solo le marcate con file nuovi (la 14, ripara Meta, resta marcata)
   - con «Other» l'utente scrive i numeri da aggiungere o togliere (es. `+9 +11 -7`, `-14` per non riparare Meta).

   Le cartelle di assets 9-13 sono vuote (`.gitkeep`): non sovrascrivono mai nulla. La voce **14 compare solo se al passo 2 il canonical è uscito `FAIL`**, ed è marcata di default; se il canonical è già a posto non si mostra. Ripeti la lista aggiornata solo se l'utente l'ha cambiata a mano.
4. **Backup**: chiedi con `AskUserQuestion`, nominando i file che verranno sovrascritti o eliminati nelle cartelle scelte:
   - «Sì, fai il backup» (consigliato): copia ciò che sostituisce in `.scaffold-backup/<data>/`
   - «No, senza backup»

5. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" [--backup] --only <cartelle scelte, separate da virgola, es. views/layouts,assets/main/js> <root>`.
   Se la voce 14 (ripara Meta) è rimasta marcata: applica la correzione di `rules/meta.md` in `private/master/Foundation/Meta.php` (mai in `vendor/`), con la **stessa firma** di `render_property` del core installato; se il file ha già un `render_property`, aggiungi il caso lì dentro. Con backup, copia prima il file in `.scaffold-backup/<data>/private/master/Foundation/Meta.php`. Poi rilancia `check-meta.sh`: la riga del canonical deve essere `OK`.
   **DESIGN.md**: se lo script ha scritto `NEW DESIGN.md`, compilalo con ciò che hai raccolto al passo 2: token nel front matter (`colors` con un `primary`, `typography`, `rounded`, `spacing`) e una frase per sezione su dove si usano. Formato: https://github.com/google-labs-code/design.md (sezioni nell'ordine del commento nel file). Se non avevi raccolto nulla, lascialo vuoto. Se esisteva già (`SKIP`), non toccarlo. Se ha token, genera le variabili: `python -I "${CLAUDE_PLUGIN_ROOT}/scripts/design-tokens.py" <root>/DESIGN.md --write <root>/assets/main/css/main.css`.
6. Con backup: se `.scaffold-backup/` non è in `.gitignore`, dillo: va tolta dopo il controllo, non committata.
7. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-all.sh" <root>`.
8. Rotte e controller non li crea lo script: segui la skill `front-routes` (`PagesController@home` nei gruppi lingua, gruppo `root.` + `PagesController@index` per il redirect alla lingua preferita); la home rende `view('pages.home.index')`. Se nel backup c'erano viste referenziate dai controller (es. `base.*`), elenca i `view('...')` da aggiornare.
9. Rispondi con una tabella `file → NEW/OVER/SAME/SKIP/EDIT/DEL/TODO` (più `Meta.php → riparato` e `DESIGN.md → compilato da <file>` / `vuoto`), il percorso del backup (se fatto) e i `FAIL` rimasti, ognuno con la sua regola (`rules/<id>.md`).
