# Regola: lingue con testo lungo o alfabeto esteso (tedesco, russo, filippino...)

Vale quando il website ha fra le lingue front attive lingue che allungano il testo o usano un alfabeto con glifi che il font del design potrebbe non avere: `de`, `ru`, `uk`, `pl`, `fi`, `nl`, `fil`/`tl`, `el`... La direzione e la scrittura non cambiano: cambia la **larghezza** e, per cirillico e greco, la **copertura del font**.

## Larghezza

- Il testo tradotto dall'italiano o dall'inglese cresce del 30-40% (tedesco, russo, filippino), molto di più nelle etichette brevi ("Cerca" → "Durchsuchen"). Bottoni, voci di menu, tab, badge e card **senza larghezza fissa**: `min-width` e `padding`, mai `width` in px; testo che può andare su due righe senza rompere il componente.
- **Parole lunghe** (composti tedeschi: "Datenschutzerklärung", "Kundenzufriedenheit"): `hyphens: auto` sui testi (funziona solo con il `lang` giusto sull'`<html>` o sull'elemento) e `overflow-wrap: break-word` su titoli e contenitori stretti.
  ```css
  .content, .card-text { hyphens: auto; overflow-wrap: break-word; }
  h1, h2, h3 { overflow-wrap: break-word; }
  ```
- Menu orizzontali: con 6 voci in tedesco non ci stanno più. Prevedi l'a capo o il passaggio al menu compatto a una larghezza maggiore (breakpoint in `responsive.css`), non font più piccoli.
- Niente testo troncato con `text-overflow: ellipsis` su etichette di navigazione o bottoni: in tedesco diventa illeggibile. Va bene solo su anteprime di contenuto (titoli di card), con il testo intero in `title` o nella pagina.
- Niente testo dentro le immagini.

## Font: copertura dei glifi

- Russo, ucraino, bulgaro (cirillico) e greco: il font del design deve avere quei glifi. Molti font di marca hanno solo il latino e il browser ripiega su un font di sistema diverso, solo per quelle lettere. Controlla in `DESIGN.md` / sul sito del font; con Google Fonts aggiungi il subset (`&subset=cyrillic` o il file `cyrillic` in `unicode-range`).
- Polacco, ceco, rumeno, turco, filippino: lettere accentate ed estese (ł, ő, ș, ğ, ñ) nel `latin-ext`, stesso controllo.
- Il russo non ha corsivo "finto" accettabile in molti font: se il font non ha un vero italic cirillico, enfasi con il peso.

## No
- Niente `width` fissa in px su bottoni, tab, voci di menu.
- Niente `white-space: nowrap` su etichette tradotte, salvo prezzi, date e codici.
- Niente `hyphens: auto` senza `lang` corretto (non fa nulla) né sui titoli brevi in maiuscolo.
- Niente font senza i glifi della lingua.

Verifica: l'agente apre le pagine principali nella lingua più lunga del sito (di solito il tedesco) a 360px e a 1280px: nessun testo che sfonda o si sovrappone, bottoni e menu leggibili, nessuna lettera in un font diverso dalle altre.
