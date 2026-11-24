---
description: Riscrive lo scaffolding del front Master Laravel Enesi dai template del plugin (per progetti appena avviati con il front disallineato), con backup di ciò che sostituisce
argument-hint: "[root del progetto]"
---

## Regola d'oro

Solo per progetti appena avviati, con il front quasi vuoto: riscrive i file dei template e toglie `Views/base/`. Tutto ciò che sostituisce va prima in `.scaffold-backup/`; i file fuori dai template (pagine, componenti, …) non si toccano.

## Procedura

1. Root del progetto: `$ARGUMENTS`, altrimenti la root git della cartella corrente.
2. Prima di toccare qualcosa, mostra cosa verrebbe riscritto: elenca i file di `${CLAUDE_PLUGIN_ROOT}/templates/` che esistono già nel progetto e sono diversi, e se c'è `private/front/Main/Views/base/`. Se uno di questi file ha contenuto vero del progetto (header/footer già fatti, pagine con testo), segnalalo e **chiedi conferma**. Se l'utente ha già detto che il front è vuoto e si può procedere, vai avanti.
3. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/scaffold.sh" --force <root>`.
   - `NEW` creato, `OVER` riscritto (vecchio file nel backup), `SAME` già uguale al template, `DEL` cartella vecchia tolta (nel backup), `TODO` da fare a mano.
   - Se esce `STOP`, fermati e riporta il motivo.
4. Se `.scaffold-backup/` non è in `.gitignore`, dillo: va tolta dopo il controllo, non committata.
5. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-all.sh" <root>`.
6. Le rotte e i controller restano al progetto: `pages/home/index.blade.php` serve un'action che renda `view('pages.home.index')`. Se nel backup c'erano viste referenziate da controller (es. `base.*`), elenca i `view('...')` da aggiornare.
7. Rispondi con una tabella `file → NEW/OVER/SAME/DEL/TODO`, il percorso del backup e i `FAIL` rimasti, ognuno con la sua regola (`rules/<id>.md`).
