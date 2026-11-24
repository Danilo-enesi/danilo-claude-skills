---
name: front-meta
description: Meta tag del front Master Laravel Enesi: in ogni action che rende una vista il controller imposta title, description e canonical con Meta::set(), più og:image/og:type quando servono; Meta::render() in head stampa tutto. Fallback del core da conoscere (il canonical di default si porta dietro la query string). Attivala quando crei o modifichi un'action che fa `return view(...)`, o quando una pagina ha bisogno di SEO: «SEO della pagina», «meta title», «description», «og:image», «og:tags», «canonical», «noindex».
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
5. Verifica: `bash scripts/check-meta.sh <root>`.
6. Se segnala il **bug del core** (canonical stampato come `<meta>`): correggilo in `private/master/Foundation/Meta.php` con l'override di `render_property` (`rules/meta.md`), stessa firma del core installato, mai in `vendor/`.

## Da sapere
- Il canonical di fallback è `request()->fullUrl()`: con `?utm_...` o filtri diventa sbagliato. Per questo va sempre impostato.
- `set()` con una chiave sconosciuta ritorna `false` **in silenzio**.
- Un `og:image` con URL non valido non viene stampato.
- In `development` il robots è `noindex, nofollow` da solo.
- Una chiave nuova (es. `theme-color`): estendi la mappa in `private/master/Foundation/Meta.php`.
