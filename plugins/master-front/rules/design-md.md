# Regola: DESIGN.md è obbligatorio

Ogni progetto ha un `DESIGN.md` nella root (formato https://github.com/google-labs-code/design.md): il design del front in un posto solo, token esatti nel front matter YAML e il perché nelle sezioni.

## Sì
- Lo crea `/master-front:scaffold` se manca, compilato con il design che il front ha già (colori, font, breakpoint, spaziature); vuoto se il front non ha nulla di suo.
- Il front prende colori, font, spaziature e componenti da `DESIGN.md`; un valore che manca si aggiunge lì, non si inventa nel CSS.
- Ogni modifica al design del front (colore, font, breakpoint, componente nuovo o cambiato) si riporta in `DESIGN.md` **nella stessa modifica**.
- Il `CLAUDE.md` del progetto rimanda a `DESIGN.md` per il front (lo scaffold aggiunge la sezione «Front: design system» se il `CLAUDE.md` c'è).

## No
- Niente progetto senza `DESIGN.md`.
- Niente valori inventati in `DESIGN.md`: solo quelli che il front usa davvero.
- Niente `DESIGN.md` sovrascritto dallo scaffold: se esiste, è del progetto.
- Niente variabili CSS dei token scritte a mano: le genera `scripts/design-tokens.py` in `main.css` (skill `front-design`).

Verifica: `scripts/check-design.sh` (FAIL se manca `DESIGN.md`, WARN se il `CLAUDE.md` non lo cita).
