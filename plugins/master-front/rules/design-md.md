# Regola: DESIGN.md è obbligatorio

Ogni progetto ha un `DESIGN.md` nella root (formato https://github.com/google-labs-code/design.md): il design del front in un posto solo, token esatti nel front matter YAML e il perché nelle sezioni.

## Sì
- Lo crea `/master-front:scaffold` se manca, compilato con il design che il front ha già (colori, font, breakpoint, spaziature); vuoto se il front non ha nulla di suo.
- Il front prende colori, font, spaziature e componenti da `DESIGN.md`; un valore che manca si aggiunge lì, non si inventa nel CSS.
- Ogni modifica al design del front (colore, font, breakpoint, componente nuovo o cambiato) si riporta in `DESIGN.md` **nella stessa modifica**.
- Il `CLAUDE.md` del progetto rimanda a `DESIGN.md` per il front (lo scaffold aggiunge la sezione «Front: design system» se il `CLAUDE.md` c'è).

## Contrasto dei colori (WCAG AA)

Ogni coppia testo/sfondo del design ha un contrasto sufficiente:

| Cosa | Minimo |
|---|---|
| testo normale | **4.5:1** |
| testo grande (≥ 24px, o ≥ 18.66px in grassetto) | **3:1** |
| bordi di campi, icone che servono a capire, indicatore del focus | **3:1** contro lo sfondo vicino |

Le coppie da controllare: ogni componente con `backgroundColor` + `textColor` (`components.button-primary`), il testo del corpo sullo sfondo della pagina, i link sullo sfondo, testi sopra immagini (con il velo scuro che li regge), stati `:hover`/`:disabled` che restano leggibili. Calcolo: `python -I scripts/contrast.py <testo> <sfondo>` → `4.54:1`.

- **Design nuovo** (crei `DESIGN.md` o aggiungi colori e componenti): ogni coppia passa la soglia **prima** di finire in `DESIGN.md`. Se il colore del brand non ci arriva (es. testo bianco su un giallo), aggiungi una variante (`primary-dark`, `on-primary` scuro) e usala per il testo; il colore del brand resta per superfici e decorazioni. Scrivi in «Colors» quali coppie sono ammesse.
- **Design e codice che esistono già** (sito in produzione, colori decisi dal cliente): **non cambiarli**. Calcola le coppie, e quelle sotto soglia le metti come **miglioramento proposto** nel riepilogo del lavoro (coppia, rapporto, soglia, colore alternativo che la passa) e in «Do's and Don'ts» di `DESIGN.md` come nota. Decide il cliente.
- L'informazione non passa solo dal colore: errore = colore **e** testo o icona.

## No
- Niente progetto senza `DESIGN.md`.
- Niente valori inventati in `DESIGN.md`: solo quelli che il front usa davvero.
- Niente `DESIGN.md` sovrascritto dallo scaffold: se esiste, è del progetto.
- Niente coppia testo/sfondo sotto soglia in un design nuovo; niente colori di un design esistente cambiati per il contrasto senza chiedere.
- Niente variabili CSS dei token scritte a mano: le genera `scripts/design-tokens.py` in `main.css` (skill `front-design`).

Verifica: `scripts/check-design.sh` (FAIL se manca `DESIGN.md`, WARN se il `CLAUDE.md` non lo cita).
