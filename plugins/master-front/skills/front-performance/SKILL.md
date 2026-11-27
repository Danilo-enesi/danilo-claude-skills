---
name: front-performance
description: Caricamento veloce del front Master Laravel Enesi (Core Web Vitals) - immagine LCP con priority (eager + fetchpriority), width/height o aspect-ratio su ogni immagine (misure dall'artefatto /design di claude.ai se c'è), conversioni <conversione>-sm/-lg con le loro -webp e :srcset + sizes, collection <nome>_mobile con :sources preparati dal controller in <x-picture-webp>, iframe lazy o con facciata, video con preload, preconnect alla CDN, librerie solo nelle pagine che le usano con pages/<entità>/scripts.blade.php e assets/main/js/pages/<entità>.js. Attivala quando inserisci immagini, iframe, video o librerie JS nel front, o quando si parla di velocità: «la pagina è lenta», «Core Web Vitals», «LCP», «CLS», «immagine hero», «lazy load», «srcset», «immagine mobile», «conversioni», «versione mobile della foto», «carico una libreria solo in questa pagina», «main.js è troppo grande».
---

# Front veloce

**Regola d'oro:** la pagina scarica subito solo ciò che si vede subito, riserva lo spazio di ciò che arriva dopo, e ogni pagina carica solo il suo JavaScript.

Percorsi relativi alla radice del plugin (`../../` da questa skill). Regole: `rules/images-loading.md`, `rules/scripts-loading.md`, `rules/head.md`.

## Immagini

1. Sempre `<x-picture-webp>` (`rules/components-reuse.md`): webp e `loading="lazy"` di default.
2. **L'immagine più grande visibile senza scrollare** (hero, cover del dettaglio): `priority`. Una sola per pagina. Se è uno sfondo CSS: `<link rel="preload" as="image" fetchpriority="high">` con `@push('styles')`.
3. **`width` e `height`** su ogni immagine, o una classe con `aspect-ratio` (nome con `ratio`). Misure, in ordine: artefatto `/design` di claude.ai del progetto (leggilo con il tool Artifact e usa le misure del componente così come sono) → `DESIGN.md` → conversione della media nel model → misure reali del file statico.
4. **Due larghezze**: ogni conversione mostrata a misure diverse fra mobile e desktop si registra come `<conversione>-sm` e `<conversione>-lg`, **ognuna con la sua `-webp`** (`-sm-webp`, `-lg-webp`), definite nel model con **`Fit::Max` e la sola larghezza**: l'immagine non si deforma né si taglia (niente `Crop`, `Stretch`, `Fill`, `Contain`). Nella vista `conversion="<conversione>-lg"` + `:srcset="['800w' => 'card-sm', '960w' => 'card-lg']"` (larghezze vere) + `sizes` (obbligatorio). Codice del model in `rules/images-loading.md`.
5. **Immagine mobile caricata nell'admin** (altro taglio o altro design): collection `<nome>_mobile` (`singleFile`, campo `MediaLibrary` nel `config.php`) con la conversione `<conversione>-mobile` + `-mobile-webp` (anche lei `Fit::Max`). Il **controller** passa `:sources` solo se l'immagine c'è: `$mobile ? ['(max-width: 767.98px)' => [$mobile, '<conversione>-mobile']] : []`; senza, la principale (`-sm`/`-lg`) vale anche per il telefono.

## Iframe e video

6. `<iframe>` con `loading="lazy"` e `title`; YouTube, Vimeo, Maps meglio come **facciata** (anteprima + `<button>` che inserisce l'iframe al click, dopo il consenso cookie).
7. `<video>` con `preload="none"` (o `metadata`) e `poster`.

## Script

8. In `partials/base/scripts.blade.php` solo ciò che serve a tutte le pagine.
9. Libreria di una pagina o di un componente: `@push('scripts')` / `@pushOnce` nella sua vista.
10. Pagina con **molte librerie o molto JS suo**: `pages/<entità>/scripts.blade.php` (solo `@push` di `<script src>` e `<link>`, incluso dalla pagina con `@include('pages.<entità>.scripts')`) + il codice in `assets/main/js/pages/<entità>.js`, fuori dal bundle. Logica leggera di una pagina: resta in `main.js`.
11. Niente `async`/`defer` sugli script del front per ora.

## Head

12. `<link rel="preconnect" href="https://cdn.ene.si">` (senza `crossorigin`) prima dei CSS: è nel template di `head`.

## Verifica

- `bash scripts/check-views.sh <root>` (immagini senza dimensioni, più `priority`, `:srcset` senza `sizes`, iframe senza `loading`, `<script>` inline) e `bash scripts/check-head.sh <root>` (preconnect).
- L'agente misura: Lighthouse (DevTools → Lighthouse → Performance, modalità mobile) o la skill `agent-skills:webperf` sulle pagine toccate: elemento LCP = l'immagine con `priority`, CLS vicino a 0, nessuna libreria scaricata in pagine che non la usano (DevTools → Network).

## No
- Niente immagine LCP lazy, niente `priority` su più immagini.
- Niente immagine senza dimensioni né `aspect-ratio`.
- Niente libreria in tutte le pagine per usarla in una.
- Niente JavaScript nella Blade, nemmeno in `pages/<entità>/scripts.blade.php`.
