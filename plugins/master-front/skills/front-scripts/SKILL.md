---
name: front-scripts
description: Il file `Views/partials/base/scripts.blade.php` del front Master Laravel Enesi: config window.front come primo script, librerie (CDN o assets/main/lib) prima dei nostri script, Version::get() e split debug/produzione (beers.js + main.js vs base.min.js), callbacks di Beers dalla sessione. Attivala quando aggiungi un JS o una libreria JS al sito, o tocchi window.front: «carico una libreria js», «aggiungo uno script», «window.front», «scripts.blade.php», «callbacks di Beers».
---

# scripts.blade.php

**Regola d'oro:** prima `window.front`, poi le librerie, poi i nostri script, poi i callbacks. Solo script, niente markup.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. Parti da `templates/views/partials/base/scripts.blade.php`.
2. Rispetta l'ordine (`rules/scripts.md`):
   1. `<script>window.front = {...}</script>` con le traduzioni (config di default, non toglierla)
   2. librerie: prima `bash scripts/cdn.sh <nome>` (skill `front-cdn`); se c'è, da `//cdn.ene.si/...`, altrimenti `assets/main/lib/<libreria>/`; sempre caricate
   3. blocco `@if(config('app.debug'))`: beers.js + main.js (+ moduli), altrimenti `base.min.js`
   4. blocco `@if(session()->has('callbacks'))` con `Beers.callbacks.fireList`
3. Ogni script locale dentro `\Master\Facades\Version::get(...)` (`rules/assets-versioning.md`).
4. **Dove va il nostro JS** (`rules/css-split.md`):
   - logica di una pagina del front (slider, filtri, form, toggle...) → **in `main.js`**, in una sezione per pagina che parte solo se la pagina c'è (elemento presente o `window.front.route`);
   - funzionalità **complessa** che gestisce molte cose (ecommerce: carrello e checkout; `map.js`: mappa, marker, filtri, popup) → modulo `<nome>.js`: entra nel ramo debug **e** nel bundle `base.min.js`, oppure `@push('scripts')` solo dalle pagine che lo usano.
5. Verifica: `bash scripts/check-scripts.sh <root>`.

## No
- Niente librerie dopo i nostri script.
- Niente markup: il bottone torna-su va nel layout o in un partial.
