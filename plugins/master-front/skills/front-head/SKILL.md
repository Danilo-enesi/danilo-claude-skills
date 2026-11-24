---
name: front-head
description: Il file `Views/partials/base/head.blade.php` del front Master Laravel Enesi: Meta::render(), cookie banner, preconnect e Google Fonts bloccati con Meta::googleFonts(), librerie CSS, i nostri CSS con Version::get() e split debug/produzione (main.css + responsive.css vs base.min.css), icone, Google tag. Attivala quando aggiungi un CSS, un font, una libreria CSS o un'icona al sito, o quando imposti il Google tag: «aggiungo un font», «carico una libreria css», «head.blade.php», «google analytics».
---

# head.blade.php

**Regola d'oro:** prima i meta e il banner, poi le librerie, poi i nostri CSS. Tutto versionato, tutto di terze parti bloccato.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. Parti da `templates/views/partials/base/head.blade.php`.
2. Rispetta l'ordine (`rules/head.md`):
   1. `{!! Meta::render() !!}`
   2. `{!! Dom::renderCookieBanner() !!}`, se il sito gestisce i cookie
   3. font **facoltativi**, commentati nel template: se il sito ne usa, togli il commento Blade (preconnect compresi) e metti i suoi URL in `{!! Meta::googleFonts('url1', 'url2') !!}`; se non ne usa, lascia tutto commentato
   4. librerie CSS: prima `bash scripts/cdn.sh <nome>` (skill `front-cdn`); se c'è, da `//cdn.ene.si/...`, altrimenti `assets/main/lib/<libreria>/`, minificate
   5. blocco `@if(config('app.debug'))`: beers.css + main.css + responsive.css, altrimenti `base.min.css`
   6. favicon; icone web-app **facoltative** (commentate: si attivano con i png in `assets/main/icons/`); Google tag
3. Ogni asset locale dentro `\Master\Facades\Version::get(...)` (`rules/assets-versioning.md`).
4. Un CSS nostro nuovo: entra nel ramo debug **e** nel bundle `base.min.css`.
5. Verifica: `bash scripts/check-head.sh <root>`.

## No
- Niente `<link href="https://fonts.googleapis.com/...">` diretto (`rules/cookie-consent.md`).
- Niente `<title>`/`<meta>` a mano (`rules/meta.md`).
