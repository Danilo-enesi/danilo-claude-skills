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

## Tabelle di dati: `th scope` e nome della tabella

Una tabella del front contiene sempre dati (orari, prezzi, confronti, riepilogo d'ordine): per l'impaginazione si usano grid e flex. Due cose obbligatorie:

- **Ogni cella di intestazione è `<th>` con `scope`**: `scope="col"` per le intestazioni di colonna, `scope="row"` per la prima cella di una riga che la descrive. Il lettore di schermo legge «Prezzo: 25 €» invece di un elenco di numeri senza contesto. `<th>` già si vede come intestazione: non cambia nulla a schermo.
- **La tabella ha un nome**, senza aggiungere testo visibile che il design non prevede:
  - c'è già un titolo visibile sopra (`<h2>`, `<h3>`) → `aria-labelledby` verso il suo `id`, niente `<caption>`;
  - non c'è un titolo → `<caption class="visually-hidden">` (classe di Bootstrap 5: il lettore di schermo la legge, a schermo non si vede).

```blade
<h2 id="hours-title">@lang('front::contacts.hours')</h2>
<table class="table" aria-labelledby="hours-title">
    <thead>
        <tr><th scope="col">@lang('front::contacts.day')</th><th scope="col">@lang('front::contacts.time')</th></tr>
    </thead>
    <tbody>
        @foreach($hours as $row)
            <tr><th scope="row">{{ $row['day'] }}</th><td>{{ $row['time'] }}</td></tr>
        @endforeach
    </tbody>
</table>

{{-- senza titolo visibile --}}
<table class="table">
    <caption class="visually-hidden">@lang('front::orders.summary')</caption>
    ...
</table>
```

- Le tabelle di impaginazione esistono solo nelle email, con `role="presentation"` (`mail.md`): lì niente `scope` né nome.

: tastiera e focus

Vale per **qualunque** finestra o pannello che si apre sopra la pagina: Bootstrap, Beers (`beers-a11y.md`) o scritto da te. Bootstrap e Beers lo fanno già; un componente tuo deve fare tutto questo da sé.

| Cosa | Come |
|---|---|
| Ruolo | modale e offcanvas: `role="dialog"` `aria-modal="true"` + `aria-labelledby` verso il suo titolo (o `aria-label`) |
| Il bottone che apre | `<button type="button" aria-expanded="false" aria-controls="<id>">`; `aria-expanded="true"` mentre è aperto |
| Apertura | il focus entra: sul primo elemento focalizzabile, o sul pannello (`tabindex="-1"`) |
| Dentro | Tab e Shift+Tab girano solo fra gli elementi del pannello (modale e offcanvas); la pagina sotto non si raggiunge (`inert` sul resto, o il giro del Tab) |
| **Esc** | chiude. Unica eccezione: una finestra che richiede una scelta (conferma obbligatoria), che non ha nemmeno la ✕ |
| Chiusura | **il focus torna al bottone che l'ha aperta** (ricordalo all'apertura: `document.activeElement`) |
| ✕ | `<button type="button" aria-label="{{ __('front::general.close') }}">` |
| Menu a tendina | Esc chiude e il focus torna al bottone; qui il Tab può uscire (e chiude il menu), non si intrappola |

Ordine di preferenza: componente di Bootstrap (`modal`, `offcanvas`, `dropdown`) → dialog di Beers → `<dialog>` nativo con `showModal()` (Esc, focus dentro e pagina sotto inerte già fatti; il focus di ritorno controllalo) → componente scritto a mano, con questo schema:

```js
// assets/main/js/main.js: offcanvas scritto a mano
function openPanel(panel, opener) {
    const main = document.querySelector('main');
    const focusables = () => panel.querySelectorAll('a[href], button:not([disabled]), input:not([disabled]), select, textarea, [tabindex]:not([tabindex="-1"])');

    function onKey(e) {
        if (e.key === 'Escape') { close(); return; }
        if (e.key !== 'Tab') return;
        const items = focusables();
        if (!items.length) { e.preventDefault(); return; }
        const first = items[0], last = items[items.length - 1];
        if (e.shiftKey && document.activeElement === first) { e.preventDefault(); last.focus(); }
        else if (!e.shiftKey && document.activeElement === last) { e.preventDefault(); first.focus(); }
    }
    function close() {
        panel.hidden = true;
        opener.setAttribute('aria-expanded', 'false');
        main.inert = false;
        panel.removeEventListener('keydown', onKey);
        opener.focus();                                     // il focus torna a chi ha aperto
    }

    panel.hidden = false;
    opener.setAttribute('aria-expanded', 'true');
    main.inert = true;                                      // la pagina sotto non si raggiunge
    panel.addEventListener('keydown', onKey);
    panel.querySelector('[data-close]')?.addEventListener('click', close, { once: true });
    (focusables()[0] || panel).focus();
}
```

## Target da toccare: almeno 24×24px, meglio 44×44px

Tutto ciò che si clicca o si tocca (link, bottoni, icone, pallini degli slider, ✕, social, checkbox) ha un'area attiva di **almeno 24×24px** (WCAG 2.2, livello AA), **44×44px** per i controlli principali e su mobile (Apple e Google). Con target più piccoli o troppo vicini si tocca quello accanto.

- L'area si allarga con `padding` o `min-width`/`min-height`, non ingrandendo l'icona:
  ```css
  .icon-button { display: inline-flex; align-items: center; justify-content: center; min-width: 44px; min-height: 44px; }
  ```
- Link nel testo di un paragrafo: esenti (la riga di testo basta). Elenchi di link fitti (menu del footer, tag): spazio verticale fra le voci (`padding-block` sul link, non `margin` sull'`li`, così l'area cliccabile cresce).
- Checkbox e radio: la `<label>` cliccabile accanto conta come area: tienila attaccata al campo.
- Due target piccoli vicini: almeno 24px fra i loro centri.

## Reflow: niente scroll orizzontale a 320px

Con lo zoom al 400% una pagina larga 1280px diventa larga 320px: chi ha bassa visione la usa così. A **320px di larghezza** tutto deve stare in una colonna, leggibile, **senza scroll orizzontale** e senza perdere contenuti o funzioni.

- Larghezze fluide: `max-width`, `%`, `fr`, `minmax()`; niente `width` fissa in px su contenitori, colonne, card, testo.
- Testo in `rem`, `line-height` senza unità; niente `height` fissa su ciò che contiene testo (con il testo ingrandito esce dal box).
- Parole e URL lunghi: `overflow-wrap: break-word` sui contenitori di testo.
- Unica eccezione: contenuti che hanno bisogno di due dimensioni (tabelle larghe, mappe, grafici). La tabella scorre **dentro il suo contenitore** (`.table-responsive` di Bootstrap), non la pagina.
- Niente `white-space: nowrap` su testi lunghi, niente `overflow: hidden` che taglia contenuto, niente `user-scalable=no` o `maximum-scale=1` nel viewport (il core mette `maximum-scale=5.0`: va bene).



Chi ha attivato "riduci movimento" nel sistema (vertigini, disturbi vestibolari, epilessia) non deve vedere animazioni, parallax, scroll animato né slider che partono da soli.

- In `responsive.css` (è una `@media`, regola `css-split`), un blocco che spegne il movimento:
  ```css
  @media (prefers-reduced-motion: reduce) {
      *, *::before, *::after {
          animation-duration: 0.01ms !important;
          animation-iteration-count: 1 !important;
          transition-duration: 0.01ms !important;
          scroll-behavior: auto !important;
      }
      .block-image-full--parallax { background-attachment: scroll; }   /* parallax e simili: fermi */
  }
  ```
- Nel JS, prima di avviare un movimento (autoplay, parallax, `scrollIntoView({behavior: 'smooth'})`, animazioni di entrata):
  ```js
  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  ```
  e con `reduceMotion` niente autoplay, scroll istantaneo, elementi già nella posizione finale.
- Le transizioni brevi di colore/opacità (hover) vanno bene: il blocco le azzera comunque, non serve toglierle dal CSS.

## Caroselli e slider: bottone di pausa

- Uno slider che **parte da solo** ha sempre un **bottone di pausa** visibile e raggiungibile con il Tab: `<button type="button" aria-label="{{ __('front::general.pause') }}">`, che diventa "riproduci" quando è fermo (cambia `aria-label` e icona). Vale per caroselli, slideshow, ticker, video in background, testi che scorrono.
- Il movimento si ferma anche con il mouse sopra e con il focus dentro lo slider (in Swiper: `autoplay: { pauseOnMouseEnter: true }` + pausa su `focusin`); con `prefers-reduced-motion` l'autoplay non parte proprio.
- Frecce e pallini sono `<button>` con `aria-label` («Slide successiva», «Vai alla slide 3»); il pallino della slide visibile ha `aria-current="true"`; le slide nascoste non ricevono il focus (`inert`, o `aria-hidden="true"` + `tabindex="-1"` sui loro link).
- Meglio nessun autoplay: se il design non lo chiede esplicitamente, lo slider parte fermo.

## No
- Niente `type="text"` per email, telefono, URL, date.
- Niente `type="number"` per CAP, telefoni, codici (perde gli zeri iniziali e mostra le frecce).
- Niente `<img>` senza `alt`, né `alt` con il nome del file (`alt="IMG_1234.jpg"`).
- Niente link esterno senza `rel="noopener noreferrer"`.
- Niente campo di un form senza `<label>` e senza `tabindex`.
- Niente `div`/`span` al posto di un tag con significato, né più di un `<h1>` per pagina.
- Niente `<table>` senza `<th scope>` nelle intestazioni e senza nome (`aria-labelledby` verso il titolo visibile, o `<caption class="visually-hidden">`); niente tabelle per impaginare nel front.
- Niente modale o offcanvas (anche scritto a mano) che non si chiude con Esc, lascia il focus sotto o non lo riporta al bottone che l'ha aperto.
- Niente target cliccabili sotto 24×24px (44×44px per i controlli principali su mobile).
- Niente scroll orizzontale della pagina a 320px (tabelle e mappe scorrono nel loro contenitore).
- Niente animazioni, parallax o autoplay senza `prefers-reduced-motion`; niente slider automatico senza bottone di pausa.

Verifica: `scripts/check-views.sh` (`<img>` senza `alt`, link esterni senza `noopener noreferrer`, layout senza `<main>`, `<table>` senza nome o con `<th>` senza `scope`: FAIL; input testuali che dal nome sembrano email/telefono/URL/data, campi di form senza `tabindex`, `<a href="#">`/`javascript:`, più di un `<h1>`: WARN); `scripts/check-assets.sh` (animazioni senza `prefers-reduced-motion`, Beers senza le modifiche a11y: WARN). Tastiera su modali, offcanvas e slider: l'agente li prova con il solo Tab, Invio ed Esc. Target e reflow: l'agente apre le pagine a 320px (DevTools, modalità responsive) e controlla che non ci sia scroll orizzontale e che i controlli si tocchino senza sbagliare.
