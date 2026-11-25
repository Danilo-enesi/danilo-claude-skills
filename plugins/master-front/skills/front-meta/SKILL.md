---
name: front-meta
description: Meta tag del front Master Laravel Enesi: in ogni action che rende una vista il controller imposta title, description e canonical con Meta::set(), più og:image/og:type quando servono; Meta::render() in head stampa tutto. Fallback del core da conoscere (canonical di default = URL richiesto: dal core 13.8.1 senza query string salvo `page`, prima con tutta la query string). Attivala quando crei o modifichi un'action che fa `return view(...)`, o quando una pagina ha bisogno di SEO: «SEO della pagina», «meta title», «description», «og:image», «og:tags», «canonical», «noindex».
---

# Meta tag

**Regola d'oro:** ogni action che fa `return view(...)` imposta title, description e canonical. Il controller li imposta, `Meta::render()` li stampa.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. Nel controller, prima di `view()` (`rules/meta.md`):
   ```php
   Meta::set('title', $model->meta_title ?: $model->title);
   Meta::set('description', $model->meta_description ?: $model->summary);
   Meta::set('canonical', $model->url); // dettaglio: URL con gli slug giusti
   ```
   Pagine statiche: testi da `__('front::controllers.<pagina>_meta_title')` / `_meta_desc`, canonical `Front::route('<nome>')`.
2. og:tags:
   - `Meta::set('og:image', $coverUrl)` se la pagina ha un'immagine sua (altrimenti il logo del website);
   - `Meta::set('og:type', 'article' | 'product')` nei dettagli;
   - `og:title`/`og:description` solo se diversi da title/description; `og:url`, `og:locale`, `twitter:*` mai.
3. Liste paginate: canonical con la sola `page` (> 1), senza filtri; la pagina 1 è la lista base (`?page=1` → redirect 301 alla lista base, codice in `rules/meta.md`).
4. Ricerca, area utente, carrello: `Meta::set('robots', 'noindex, nofollow')` (title e description restano, canonical facoltativo).
5. Sito con 2+ lingue front: alternate hreflang e x-default con `$this->setAlternates(...)` (skill `front-alternates`).
6. Verifica: `bash scripts/check-meta.sh <root>`.
7. Se segnala il **bug del core** (canonical stampato come `<meta>`): correggilo in `private/master/Foundation/Meta.php` con l'override di `render_property` (`rules/meta.md`), stessa firma del core installato, mai in `vendor/`.

8. Se segnala il **canonical di fallback con la query string** (core < 13.8.1, `request()->fullUrl()`): sovrascrivi `get` in `private/master/Foundation/Meta.php` (`rules/meta.md`). Se il core è già corretto non fare nulla.

## Da sapere
- Canonical (e `og:url`) di fallback, se non impostato:
  - **core >= 13.8.1**: URL corrente **senza query string**, tenendo solo `page` se è un intero > 1 (`?page=3&utm_source=x` → `?page=3`);
  - **core più vecchi**: `request()->fullUrl()`, con tutta la query string (`?utm_...`, filtri, ordinamenti).
  
  Sui core vecchi si corregge in locale (punto 8). In entrambi i casi è l'URL **richiesto**, non quello giusto (slug sbagliato, rotta raggiunta da un altro percorso): per questo va sempre impostato. Versione installata: `grep -A2 '"name": "enesisrl/laravel-master-core"' private/composer.lock | grep version`.
- Dal core 2.4.2 il canonical si stampa già come `<link rel="canonical">`: l'override di `render_property` del punto 7 serve solo ai core più vecchi.
- `set()` con una chiave sconosciuta ritorna `false` **in silenzio**.
- Un `og:image` con URL non valido non viene stampato.
- In `development` il robots è `noindex, nofollow` da solo.
- Una chiave nuova (es. `theme-color`): estendi la mappa in `private/master/Foundation/Meta.php`.
