# Regola: markup HTML semantico e accessibile (skill `front-html`)

## Tag semantici

- Landmark: `<header>`, `<nav>`, **un** `<main>` (nel layout), `<section>` con titolo, `<article>`, `<aside>`, `<footer>`; elenchi con `<ul>`/`<ol>`.
- **Un solo `<h1>`** per pagina, poi `h2`, `h3`... senza saltare livelli.
- Azione → `<button>`; navigazione → `<a href>`. Mai `<a href="#">`, `href="javascript:"`, `div` cliccabili.

## Input: il tipo giusto per il dato

| Dato | Markup |
|---|---|
| email | `type="email"` + `autocomplete="email"` |
| telefono | `type="tel"` + `autocomplete="tel"` |
| URL / sito web | `type="url"` |
| numero da calcolare (quantità, età) | `type="number"` (+ `min`/`max`/`step`) |
| codice fatto di cifre ma non da calcolare (CAP, CVV, OTP, P.IVA) | `type="text"` + `inputmode="numeric"` (+ `pattern`); `autocomplete="postal-code"` / `"one-time-code"` |
| decimale con la virgola | `type="text"` + `inputmode="decimal"` |
| data / ora / data e ora | `type="date"` / `"time"` / `"datetime-local"` |
| password | `type="password"` + `autocomplete="current-password"` / `"new-password"` |
| ricerca | `type="search"` + `inputmode="search"` |
| nome, cognome, indirizzo | `type="text"` + `autocomplete="given-name"` / `"family-name"` / `"street-address"` |
| colore, intervallo | `type="color"` / `"range"` |
| scelta da elenco | `<select>`, radio o checkbox, non un testo libero |

- `inputmode` cambia solo la tastiera mobile: si usa quando `type` non basta (cifre che non sono numeri).
- **`tabindex` nei form**: campi e bottone di invio hanno `tabindex` nell'ordine logico di compilazione (`1`, `2`, `3`... senza buchi; più form nella stessa pagina continuano la numerazione). Gli elementi che non sono campi (link nel testo, icone) restano senza `tabindex`, o con `tabindex="-1"` se non devono ricevere il focus.
  - Attenzione: un `tabindex` positivo porta quei campi **prima** di tutto il resto della pagina nell'ordine del Tab (menu compreso). Il DOM deve comunque essere già nell'ordine giusto: `tabindex` lo rende esplicito, non lo ripara.
- Fuori dai form, `tabindex="0"` solo su un controllo personalizzato che non è già focalizzabile, `tabindex="-1"` per un elemento che riceve il focus da JS (modale, messaggio d'errore).
- Ogni campo ha la sua `<label for>` (o `aria-label` se la label non si vede); i messaggi d'errore sono associati con `aria-describedby`.

## Immagini: sempre `alt`

- Ogni `<img>` ha `alt`: descrittivo se l'immagine porta informazione (tradotto: `:alt="__('front::...')"` o il titolo del record), `alt=""` se è decorativa.
- Con `<x-picture-webp>` si passa `alt` / `:alt`.
- Loghi: `alt` = nome del marchio. Immagini dentro un link senza testo: `alt` = dove porta il link.

## Link esterni: `noopener noreferrer`

- Un link verso un altro dominio ha `rel="noopener noreferrer"`; se apre una nuova scheda, `target="_blank"` **e** lo stesso `rel`.
  ```blade
  <a href="https://www.esempio.it" target="_blank" rel="noopener noreferrer">...</a>
  ```
- I link interni (`Front::route(...)`, `$model->url`) non lo hanno.

## No
- Niente `type="text"` per email, telefono, URL, date.
- Niente `type="number"` per CAP, telefoni, codici (perde gli zeri iniziali e mostra le frecce).
- Niente `<img>` senza `alt`, né `alt` con il nome del file (`alt="IMG_1234.jpg"`).
- Niente link esterno senza `rel="noopener noreferrer"`.
- Niente campo di un form senza `<label>` e senza `tabindex`.
- Niente `div`/`span` al posto di un tag con significato, né più di un `<h1>` per pagina.

Verifica: `scripts/check-views.sh` (`<img>` senza `alt`, link esterni senza `noopener noreferrer`, layout senza `<main>`: FAIL; input testuali che dal nome sembrano email/telefono/URL/data, campi di form senza `tabindex`, `<a href="#">`/`javascript:`, più di un `<h1>`: WARN).
