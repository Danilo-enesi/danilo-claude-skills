---
name: front-html
description: Semantica e accessibilità dell'HTML/Blade che scrivi nel front Master Laravel Enesi - tag semantici (header, nav, main, section, article, aside, footer), un solo h1 e titoli in ordine, button vs link, form accessibili (label, type/inputmode/autocomplete giusti, tabindex, errori), alt sulle immagini, rel="noopener noreferrer" sui link esterni, ARIA solo quando serve, focus visibile, modali e offcanvas (anche scritti a mano) con Esc e focus che torna al bottone, prefers-reduced-motion, slider con pausa, Beers accessibile. Attivala OGNI VOLTA che scrivi o modifichi markup del front: «crea la pagina», «fai il form di contatto», «crea la card», «header/footer», «menu», «converti questo mockup», «rendilo accessibile», «semantica», «modale», «offcanvas», «slider / carosello», «animazione».
---

# HTML semantico e accessibile

**Regola d'oro:** ogni pezzo di markup usa il tag che dice cosa è, e si usa anche senza mouse e senza vista: tastiera, screen reader, zoom.

Percorsi relativi alla radice del plugin (`../../` da questa skill). Regola: `rules/html-markup.md`.

**Lingue difficili:** se il sito ha (o sta per avere) una lingua RTL (`ar`, `he`, `fa`, `ur`), CJK (`zh`, `ja`, `ko`) o con testo lungo / alfabeto esteso (`de`, `ru`, `pl`, `fil`...), carica anche la skill `front-lang-css` prima di scrivere: controlla le lingue nei `'locale'` di `Routes/web.php`.

## 1. Struttura della pagina (landmark)

| Tag | Dove |
|---|---|
| `<header>` | intestazione del sito (in `partials/header`) o di un `<article>` |
| `<nav aria-label="...">` | menu principale, menu del footer, breadcrumb: ognuno il suo `aria-label` se ce n'è più di uno |
| `<main>` | **uno** per pagina, nel layout attorno a `@yield('content')` |
| `<section>` | una parte della pagina **con un suo titolo** (`h2`...) |
| `<article>` | un contenuto che sta in piedi da solo: post, prodotto, card di una notizia |
| `<aside>` | contenuto collaterale: sidebar, correlati |
| `<footer>` | piede del sito (in `partials/footer`) o di un `<article>` |
| `<address>` | contatti del titolare (in footer) |
| `<figure>` + `<figcaption>` | immagine con didascalia |
| `<time datetime="2026-11-24">` | date |
| `<ul>` / `<ol>` | elenchi: voci di menu, card in griglia, passi |

- `<div>` / `<span>` solo per impaginare, quando nessun tag ha un significato.
- `lang` sull'`<html>` come da `rules/layout-main.md`: `{{ Websites::currentLanguage('iso_code2') }}`, oppure `{{ $htmlLang }}` + `dir` dal composer sui siti con lingue RTL/CJK (skill `front-lang-css`). Solo `pages/maintenance.blade.php`, che non ha dati, usa `app()->getLocale()`. Un testo in un'altra lingua ha il suo `lang`.

## 2. Titoli

- **Un solo `<h1>`** per pagina: il titolo della pagina.
- Poi `h2` per le sezioni, `h3` dentro un `h2`... senza saltare livelli.
- Il livello dice la gerarchia, non la grandezza: per un testo grande che non è un titolo si usa una classe (`.text-heading-lg`), per un titolo piccolo si cambia lo stile, non il livello.

## 3. Interazione

- **Porta altrove** (un'altra pagina, un'ancora) → `<a href="...">`. **Fa un'azione** (apre un menu, una modale, invia) → `<button type="button">` (o `type="submit"` nei form).
- Mai `<a href="#">`, `href="javascript:..."` o `<div>`/`<span>` cliccabili.
- Bottoni e link solo con icona: testo accessibile con `aria-label="Chiudi"` (tradotto con `{{ __() }}`) o `<span class="visually-hidden">`.
- Il focus si vede sempre: niente `outline: none` senza un `:focus-visible` alternativo.
- Menu e modali: `aria-expanded` sul bottone che li apre, `aria-controls` verso l'elemento; Bootstrap lo fa già con i suoi componenti, usali.
- **Modali e offcanvas, anche scritti a mano** (`rules/html-markup.md`, sezione Modali): `role="dialog"` `aria-modal="true"`, il focus entra all'apertura, Tab resta dentro, **Esc chiude**, alla chiusura **il focus torna al bottone che l'ha aperto**, ✕ con `aria-label`. Prima scelta Bootstrap o Beers, poi `<dialog>` nativo, poi codice tuo con lo schema della regola.
- **Beers** (dialog, notifiche, errori dei form): la versione del progetto deve avere le modifiche a11y. `check-assets.sh` lo segnala; se mancano, applicale funzione per funzione (`rules/beers-a11y.md`), mai sovrascrivendo `beers.js`.

## 3b. Movimento e slider

- Animazioni, parallax, scroll animato, autoplay: blocco `@media (prefers-reduced-motion: reduce)` in `responsive.css` e, nel JS, `matchMedia('(prefers-reduced-motion: reduce)')` prima di avviare il movimento (`rules/html-markup.md`, sezione Movimento).
- Slider o qualunque contenuto che si muove da solo (caroselli, ticker, video di sfondo): **bottone di pausa** visibile e raggiungibile con il Tab; pausa anche con mouse sopra e focus dentro; frecce e pallini sono `<button>` con `aria-label`. Se il design non chiede l'autoplay, lo slider parte fermo.

## 4. Form

- Ogni campo ha la sua `<label for="id">` visibile (o `aria-label` solo se il design non ha label); il placeholder **non** sostituisce la label.
- **Tipo giusto** per il dato (tabella in `rules/html-markup.md`): `type="email"`, `"tel"`, `"url"`, `"date"`, `"number"`; codici di cifre (CAP, OTP) con `type="text" inputmode="numeric"`; `autocomplete` corretto (`email`, `tel`, `given-name`, `postal-code`...).
- **`tabindex`** su campi e bottone di invio, nell'ordine logico di compilazione (`rules/html-markup.md`, sezione Form).
- Gruppi (radio, indirizzo): `<fieldset>` + `<legend>`.
- Obbligatori: `required` (e l'asterisco spiegato a parole); errori: `aria-invalid="true"` sul campo e il messaggio collegato con `aria-describedby`, vicino al campo.
- Il bottone di invio è un `<button type="submit">` con un testo che dice cosa fa («Invia richiesta», non «OK»).

## 5. Immagini e media

- Ogni `<img>` ha `alt`: descrittivo e tradotto se porta informazione, `alt=""` se decorativa; con `<x-picture-webp>` si passa `:alt`.
- Video: sottotitoli se c'è parlato; mai autoplay con audio.
- Icone decorative (font icon, svg): `aria-hidden="true"`.

## 5b. Tabelle di dati

- Obbligatori: `<th scope="col">` / `scope="row"` su ogni intestazione, e un nome per la tabella: `aria-labelledby` verso il titolo visibile sopra, o `<caption class="visually-hidden">` se un titolo non c'è (`rules/html-markup.md`, sezione Tabelle). Niente tabelle per impaginare.

## 6. Link esterni

- Verso un altro dominio: `rel="noopener noreferrer"`; se apre una nuova scheda, anche `target="_blank"`.

## 7. ARIA

- Prima il tag giusto, ARIA solo quando l'HTML non basta (`aria-expanded`, `aria-current="page"` sulla voce di menu attiva, `aria-live` per messaggi che compaiono dopo un'azione).
- Mai `role="button"` su un `<div>`: si usa `<button>`.

## 8. Colori e testo

- Contrasto almeno AA (4.5:1 per il testo normale, 3:1 per testo grande e focus) con i colori di `DESIGN.md`: calcolo con `scripts/contrast.py`, regole per design nuovi ed esistenti in `rules/design-md.md` (skill `front-design`). L'informazione non passa solo dal colore (errore = colore **e** testo/icona).
- Testo che si può ingrandire: misure in `rem`, niente testo dentro le immagini.
- **Target da toccare** almeno 24×24px, 44×44px per i controlli principali su mobile: area allargata con `padding`/`min-height`, non con icone più grandi (`rules/html-markup.md`, sezione Target).
- **Reflow**: a 320px di larghezza (= zoom 400%) niente scroll orizzontale, tutto in una colonna; larghezze fluide, niente `width`/`height` fisse su testo; tabelle larghe dentro `.table-responsive` (`rules/html-markup.md`, sezione Reflow).
- **Skip link** «Vai al contenuto» primo elemento del body, verso `<main id="main">`: è nel layout (`rules/layout-main.md`), non toglierlo.

## 9. Verifica

- `bash scripts/check-views.sh <root>`: `<img>` senza `alt`, link esterni senza `rel`, input testuali per email/telefono/URL/data, `<a href="#">`, più di un `<h1>` o nessun `<main>` nel layout.
- `bash scripts/check-assets.sh <root>`: animazioni senza `prefers-reduced-motion`, Beers senza le modifiche a11y.
- L'agente: primo Tab sulla pagina → compare lo skip link e porta al contenuto; pagina a 320px senza scroll orizzontale e con controlli facili da toccare; tutto il percorso con il solo **Tab** (ordine sensato, focus sempre visibile); ogni modale, offcanvas e menu aperto con Invio, chiuso con Esc, focus che torna al bottone; slider fermabile; poi Lighthouse → Accessibility.

## No
- Niente `div` dove c'è un tag con un significato (`button`, `nav`, `ul`, `article`...).
- Niente titoli scelti per la grandezza.
- Niente campo senza label, immagine senza `alt`, link esterno senza `rel="noopener noreferrer"`.
- Niente modale/offcanvas che non si chiude con Esc o perde il focus alla chiusura, anche se scritto a mano.
- Niente movimento che non rispetta `prefers-reduced-motion`, né slider automatico senza pausa.
