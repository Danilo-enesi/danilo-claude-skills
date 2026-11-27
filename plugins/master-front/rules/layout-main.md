# Regola: il layout principale

`layouts/main.blade.php` ha sempre questi pezzi, in quest'ordine:

```blade
<html lang="{{ Websites::currentLanguage('iso_code2') }}">
  <head>
    {{-- Head --}}
    @include('partials.base.head')
    @stack('styles')
  </head>
  <body class="lang-{{ Websites::currentLanguage('iso_code2') }} route-{{ Front::currentRouteName() }}">
    {{-- Skip link --}}
    <a href="#main" class="visually-hidden-focusable skip-link">@lang('front::general.skip_to_content')</a>

    {{-- Content --}}
    <main class="main" id="main">
      @yield('content')
    </main>

    {{-- Scripts --}}
    @include('partials.base.scripts')
    @stack('scripts')
  </body>
</html>
```

Sito con una lingua RTL o CJK: `<html lang="{{ $htmlLang }}" dir="{{ $htmlDir }}">`, con le variabili dal view composer di `lang-rtl.md` (skill `front-lang-css`).


## Skip link

Primo elemento del `<body>`: `<a href="#main" class="visually-hidden-focusable skip-link">` verso il `<main id="main">`. È invisibile finché non riceve il focus (primo Tab sulla pagina): chi naviga con la tastiera o con il lettore di schermo salta header e menu e arriva al contenuto, invece di ripassare tutto il menu a ogni pagina.

- `visually-hidden-focusable` è di Bootstrap 5; la classe `skip-link` serve solo a dargli posizione e stile quando compare (in `main.css`: in alto a sinistra, sopra l'header, `z-index` alto, colori del design con contrasto AA).
- Testo dalla traduzione `front::general.skip_to_content` («Vai al contenuto»): aggiungila nelle lingue del sito (gestione traduzioni nel DB, `translations.md`).
- Un layout alternativo (landing, vuoto) ha lo stesso skip link se ha un header o un menu prima del contenuto.

## Sì
- `@stack('styles')` **dopo** l'include di head, `@stack('scripts')` **dopo** l'include di scripts: la pagina parte da ciò che la base ha già caricato.
- Le classi `lang-` e `route-` del body sono il gancio di CSS e JS per lingua o per pagina.

## No
- Niente `@yield('styles')` / `@yield('scripts')`: un `@section` accetta un solo contributo, `@push` li somma.
- Niente meta, CSS o JS scritti direttamente nel layout.

Verifica: `scripts/check-layout.sh` · Template: `templates/views/layouts/main.blade.php`
