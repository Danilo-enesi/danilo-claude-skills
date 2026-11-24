---
name: front-meta
description: Meta tag del front Master Laravel Enesi: Meta::render() in head e Meta::set() nel controller per title, description, og:image, canonical; fallback del core da non reimplementare. Attivala quando una pagina del front ha bisogno di title/description/og:image o quando un meta «sparisce»: «SEO della pagina», «meta title», «og:image», «canonical», «noindex».
---

# Meta tag

**Regola d'oro:** i meta non si scrivono nella vista. Il controller li imposta, `Meta::render()` li stampa.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. Nel controller, prima di `view()`:
   ```php
   Meta::set('title', $model->meta_title ?: $model->description);
   Meta::set('description', $model->meta_description ?: $model->summary);
   Meta::set('og:image', $coverUrl); // se c'è una cover
   ```
2. Basta questo: og/twitter/canonical/locale li completa il core (fallback).
3. Un meta nuovo (es. `theme-color`): estendi la mappa in `private/master/Foundation/Meta.php`.
4. Regole: `rules/meta.md`.

## Da sapere
- `set()` con una chiave sconosciuta ritorna `false` **in silenzio**.
- Un `og:image` con URL non valido non viene stampato.
- In `development` il robots è `noindex, nofollow` da solo.
