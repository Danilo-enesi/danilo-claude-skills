---
name: front-html
description: Semantica e accessibilità dell'HTML/Blade che scrivi nel front Master Laravel Enesi - tag semantici (header, nav, main, section, article, aside, footer), un solo h1 e titoli in ordine, button vs link, form accessibili (label, type/inputmode/autocomplete giusti, tabindex, errori), alt sulle immagini, rel="noopener noreferrer" sui link esterni, ARIA solo quando serve, focus visibile. Attivala OGNI VOLTA che scrivi o modifichi markup del front: «crea la pagina», «fai il form di contatto», «crea la card», «header/footer», «menu», «converti questo mockup», «rendilo accessibile», «semantica».
---

# HTML semantico e accessibile

**Regola d'oro:** ogni pezzo di markup usa il tag che dice cosa è, e si usa anche senza mouse e senza vista: tastiera, screen reader, zoom.

Percorsi relativi alla radice del plugin (`../../` da questa skill). Regola: `rules/html-markup.md`.

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
- `<html lang="{{ app()->getLocale() }}">` nel layout; un testo in un'altra lingua ha il suo `lang`.

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

## 6. Link esterni

- Verso un altro dominio: `rel="noopener noreferrer"`; se apre una nuova scheda, anche `target="_blank"`.

## 7. ARIA

- Prima il tag giusto, ARIA solo quando l'HTML non basta (`aria-expanded`, `aria-current="page"` sulla voce di menu attiva, `aria-live` per messaggi che compaiono dopo un'azione).
- Mai `role="button"` su un `<div>`: si usa `<button>`.

## 8. Colori e testo

- Contrasto almeno AA (4.5:1 per il testo normale) con i colori di `DESIGN.md`; l'informazione non passa solo dal colore (errore = colore **e** testo/icona).
- Testo che si può ingrandire: misure in `rem`, niente testo dentro le immagini.

## 9. Verifica

- `bash scripts/check-views.sh <root>`: `<img>` senza `alt`, link esterni senza `rel`, input testuali per email/telefono/URL/data, `<a href="#">`, più di un `<h1>` o nessun `<main>` nel layout.
- A mano: tutto il percorso con il solo **Tab** (ordine sensato, focus sempre visibile), e un controllo con Lighthouse → Accessibility.

## No
- Niente `div` dove c'è un tag con un significato (`button`, `nav`, `ul`, `article`...).
- Niente titoli scelti per la grandezza.
- Niente campo senza label, immagine senza `alt`, link esterno senza `rel="noopener noreferrer"`.
