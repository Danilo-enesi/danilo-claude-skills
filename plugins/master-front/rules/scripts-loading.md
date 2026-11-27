# Regola: ogni script solo nelle pagine che lo usano

`partials/base/scripts.blade.php` carica ciò che serve a **tutte** le pagine: `window.front`, jQuery, Bootstrap, Beers + `main.js` (o `base.min.js`). Tutto il resto si carica solo dove serve, così le altre pagine non lo scaricano né lo eseguono.

## Dove va uno script

| Cosa | Dove |
|---|---|
| libreria o codice usato in **tutte** (o quasi) le pagine | `partials/base/scripts.blade.php` (librerie) / `main.js` (nostro) |
| logica **leggera** di una pagina (un filtro, il form di contatto, uno slider della home) | `main.js`, come oggi (`css-split.md`): poche righe non valgono un file |
| libreria usata da **una pagina** o da un componente (Swiper, Leaflet, lightGallery, datepicker...) | `@push('scripts')` nella vista che la usa; in un componente presente più volte `@pushOnce('scripts', '<nome>')` |
| pagina con **molte librerie** o **molto JavaScript suo** (configuratore, mappa con filtri, prenotazione a step) | `pages/<entità>/scripts.blade.php` + `assets/main/js/pages/<entità>.js` (sotto) |
| funzionalità complessa usata in più pagine (carrello, checkout) | `<modulo>.js` nel bundle, come oggi (`css-split.md`) |

## `pages/<entità>/scripts.blade.php`: gli script di una pagina in un posto solo

Alternativa a fare di `main.js` il baule di tutto il JavaScript del sito: quando una pagina ha bisogno di più librerie o di tanto codice suo, i suoi script vivono in una vista accanto alla pagina.

```
Views/pages/booking/
├── index.blade.php
├── show.blade.php
└── scripts.blade.php      librerie + JS della pagina, solo @push
```

```blade
{{-- pages/booking/scripts.blade.php --}}
@push('styles')
  <link href="//cdn.ene.si/flatpickr/4.6.9/flatpickr.min.css" rel="stylesheet">
@endpush

@push('scripts')
  <script src="//cdn.ene.si/flatpickr/4.6.9/flatpickr.min.js"></script>
  <script src="//cdn.ene.si/swiper/4.4.2/js/swiper.min.js"></script>
  <script src="{{ \Master\Facades\Version::get('/assets/main/js/pages/booking.js') }}"></script>
@endpush
```

```blade
{{-- pages/booking/show.blade.php --}}
@extends('layouts.main')

@section('content')
  ...
@endsection

@include('pages.booking.scripts')
```

- **Solo `@push`** con `<script src>` e `<link>`: nessun JavaScript scritto nella Blade (`no-inline.md`). I dati per il JS passano da attributi `data-*` sul markup o da `window.front`.
- Il codice della pagina sta in **`assets/main/js/pages/<entità>.js`**, uno per entità (anche se la usano `index` e `show`: dentro, controlla quale markup c'è). Parte dopo il bundle (lo stack `scripts` segue `partials.base.scripts`), quindi usa jQuery, Bootstrap e Beers.
- `pages/<entità>.js` **non entra in `base.min.js`**: si carica uguale in sviluppo e in produzione, solo nella sua pagina (eccezione di `assets-versioning.md`, come i file di lingua). Sempre con `Version::get()`.
- Anche il CSS delle librerie della pagina (`@push('styles')`) sta qui, così una libreria si aggiunge o si toglie in un file solo. Il CSS **nostro** della pagina resta in `main.css` / `<modulo>.css`.
- Librerie dalla CDN di Enesi prima di tutto (skill `front-cdn`), versioni esatte.

## No
- Niente librerie in `partials/base/scripts.blade.php` se le usa solo qualche pagina.
- Niente `main.js` che inizializza librerie caricate solo in certe pagine (se la libreria manca, `main.js` va in errore in tutte le altre): l'init sta nel `pages/<entità>.js` della pagina.
- Niente `<script>` con codice dentro `pages/<entità>/scripts.blade.php` o in un `@push`.
- Niente `async`/`defer` aggiunti agli script del front per ora: gli script inline di `partials/base` (callbacks) presuppongono jQuery già caricato.

Verifica: `scripts/check-views.sh` (FAIL su `<script>` con codice nelle viste; i `<script src>` nei `@push` sono ammessi). Che una libreria non sia caricata in tutte le pagine senza motivo lo controlla l'agente leggendo `partials/base/scripts.blade.php`.
