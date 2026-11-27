---
name: front-layout
description: Il layout principale del front Master Laravel Enesi (`Views/layouts/main.blade.php`): html lang, classi lang-/route- sul body, include di partials/base/head e partials/base/scripts con i loro stack styles/scripts, contenitore main. Attivala quando crei, rifattorizzi o controlli il layout del front: «layout del front», «main.blade.php», «@stack styles/scripts», «classi del body», «layout alternativo».
---

# Layout principale

**Regola d'oro:** il layout è uno scheletro fisso. Non contiene meta, CSS o JS propri: li include.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. Parti da `templates/views/layouts/main.blade.php`, copiato com'è.
2. Tieni i pezzi obbligatori (`rules/layout-main.md`):
   - `<html lang="{{ Websites::currentLanguage('iso_code2') }}">` (siti con lingue RTL/CJK: `<html lang="{{ $htmlLang }}" dir="{{ $htmlDir }}">`, skill `front-lang-css`)
   - `@include('partials.base.head')` + `@stack('styles')` dentro `<head>`
   - body con `lang-...` e `route-...`
   - skip link `<a href="#main" class="visually-hidden-focusable skip-link">` primo elemento del body
   - `<main class="main" id="main">@yield('content')</main>`
   - `@include('partials.base.scripts')` + `@stack('scripts')` prima di `</body>`
3. Header, footer, modali: `@include('partials.…')`.
4. Un layout alternativo (vuoto, landing) va in `layouts/` e rispetta gli stessi pezzi.
5. Verifica: `bash scripts/check-layout.sh <root>`.

## No
- Niente `@yield('styles')`/`@yield('scripts')`: si usano gli stack.
- Niente head o scripts dentro `layouts/`: stanno in `partials/base/`.
