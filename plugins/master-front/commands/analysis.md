---
description: Dry-run dello scaffolding del front Master Laravel Enesi - mostra cosa scriverebbe, sovrascriverebbe o eliminerebbe /master-front:scaffold e lo stato dei controlli, senza toccare nulla
argument-hint: "[root del progetto]"
---

## Regola d'oro

Sola lettura: **non creare né modificare nulla**.

## Procedura

1. Root del progetto: `$ARGUMENTS`, altrimenti la root git della cartella corrente.
2. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" --dry-run <root>`. Se esce `STOP`, fermati e riporta il motivo.
3. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-all.sh" <root>`.
4. Per i file `OVER` di `layouts/main.blade.php`, `partials/base/head.blade.php`, `partials/base/scripts.blade.php`, `partials/header.blade.php`, `partials/footer.blade.php`: confronta con il template in `${CLAUDE_PLUGIN_ROOT}/templates/views/` e di' se il file del progetto ha contenuto vero (header/footer già fatti) che lo scaffold cancellerebbe.
5. Rispondi con:
   - tabella `file → NEW/OVER/SAME/SKIP/DEL/TODO` (`SKIP` = Beers già presente, non si tocca), raggruppata per cartella (`views/layouts`, `views/partials`, `views/components`, `views/pages`, `views/mail`, `assets/main/css`, `assets/main/js`, `assets/mail`, `assets/main/lib|icons|images|videos|documents`, sempre installati: Beers, classi dei componenti);
   - i `FAIL` di `check-all`, ognuno con la sua regola (`rules/<id>.md`);
   - se `check-meta` segnala il canonical stampato come `<meta>`: dillo, `/master-front:scaffold` chiederà se riparare Meta;
   - una riga finale: se è sicuro lanciare `/master-front:scaffold` e su quali cartelle conviene fermarsi.
