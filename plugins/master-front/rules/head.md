# Regola: partials/base/head.blade.php

Tutto ciò che va in `<head>`: meta, cookie banner, font, link, librerie CSS, i nostri CSS, icone, gtag.

Ordine:
1. `{!! Meta::render() !!}`
2. `{!! Dom::renderCookieBanner() !!}` (se il sito gestisce i cookie), prima di ogni `<link>`/`<script>`
3. font, **facoltativi** (nel template sono commentati): preconnect + `{!! Meta::googleFonts(...) !!}`; si attivano togliendo il commento Blade
4. librerie (minificate se possibile): di default **Bootstrap** (`//cdn.ene.si/bootstrap/<versione>/css/bootstrap.min.css`)
5. i nostri CSS, con lo split di ambiente (vedi `assets-versioning`); nel ramo debug **`beers.css` per primo**, poi `main.css`, poi `responsive.css`
   - subito dopo, fuori dallo split, il **file di lingua** `assets/main/css/lang/<iso_code2>.css` se esiste: così le correzioni di una lingua sovrascrivono `main.css` e `responsive.css` (regola `css-split`). Lo stampa il componente `<x-lang-css />` (sezione "File di lingua"), non un `file_exists()` nella Blade
6. favicon (sempre); icone web-app (`apple-touch-icon`, `icon-192`) **facoltative**, commentate nel template: si attivano togliendo il commento e mettendo i png in `assets/main/icons/`; gtag

## File di lingua

`<x-lang-css />` (classe `Front\Main\Components\LangCss`, registrata in `FrontServiceProvider::boot()` con `Blade::component('lang-css', LangCss::class)`) stampa il `<link>` a `assets/main/css/lang/<iso_code2>.css` della lingua corrente, e **nulla** se la lingua non ha il file. Parametri:

| Parametro | Default | |
|---|---|---|
| `:versioned` | `true` | passa da `Version::get()`; `false` → `asset()` senza `?v=` |
| `directory` | `assets/main/css/lang` | cartella dei file di lingua, dalla web root |

Gli altri attributi (`media`, `id`, `data-*`) finiscono sul `<link>`; `rel="stylesheet"` è il default e si può sovrascrivere.

Va **dopo** il blocco `@if(config('app.debug')) … @else base.min.css @endif`, fuori dallo split: il file di lingua si carica uguale nei due ambienti e non entra in `base.min.css` (regola `assets-versioning`).

## No
- Niente preconnect a Google Fonts se il sito non carica Google Fonts: è una connessione a Google inutile, prima del consenso.
- Niente `{{ Meta::googleFonts(...) }}`: escapa l'HTML, va `{!! !!}`.
- Niente `main.css`/`responsive.css` prima di `beers.css`: i nostri stili devono poter sovrascrivere quelli di Beers.
- Niente `<title>`/`<meta>` a mano (vedi `meta`).
- Niente `<link href="https://fonts.googleapis.com/...">` diretto (vedi `cookie-consent`).

Verifica: `scripts/check-head.sh` · Template: `templates/views/partials/base/head.blade.php`
