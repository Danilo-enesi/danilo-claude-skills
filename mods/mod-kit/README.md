# mod-kit

Kit per creare mod di Claude Code per terminale con lo stile "Flightdeck"
(pane scuro, un colore per attore su bordo/titolo/legenda, griglia mono, separatori `·`).

- `template/` — scheletro di mod: `hooks/deck.tsx` (Header, Card, Meter, Kv, `tone`, `cut`, `fill`), un pane demo, test, contratto di stato.
- `scripts/new-mod.sh <nome> "<Titolo>" [cartella-padre]` — copia il template e sostituisce `__NAME__`/`__TITLE__`.
- `scripts/check.sh <cartella-mod>` — `claude plugin validate` + `claude plugin test`.

Flusso: `new-mod.sh` → modifica `register.tsx` → `check.sh` → il mod si ricarica a fine turno.
