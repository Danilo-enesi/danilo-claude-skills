# Regola: partials/base/head.blade.php

Tutto ciò che va in `<head>`: meta, cookie banner, font, link, librerie CSS, i nostri CSS, icone, gtag.

Ordine:
1. `{!! Meta::render() !!}`
2. `{!! Dom::renderCookieBanner() !!}` (se il sito gestisce i cookie), prima di ogni `<link>`/`<script>`
3. preconnect + `Meta::googleFonts(...)`
4. librerie (minificate se possibile)
5. i nostri CSS, con lo split di ambiente (vedi `assets-versioning`); nel ramo debug **`beers.css` per primo**, poi `main.css`, poi `responsive.css`
6. icone, gtag

## No
- Niente `main.css`/`responsive.css` prima di `beers.css`: i nostri stili devono poter sovrascrivere quelli di Beers.
- Niente `<title>`/`<meta>` a mano (vedi `meta`).
- Niente `<link href="https://fonts.googleapis.com/...">` diretto (vedi `cookie-consent`).

Verifica: `scripts/check-head.sh` · Template: `templates/views/partials/base/head.blade.php`
