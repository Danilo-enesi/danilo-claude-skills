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
    {{-- Content --}}
    <main class="main">
      @yield('content')
    </main>

    {{-- Scripts --}}
    @include('partials.base.scripts')
    @stack('scripts')
  </body>
</html>
```

## Sì
- `@stack('styles')` **dopo** l'include di head, `@stack('scripts')` **dopo** l'include di scripts: la pagina parte da ciò che la base ha già caricato.
- Le classi `lang-` e `route-` del body sono il gancio di CSS e JS per lingua o per pagina.

## No
- Niente `@yield('styles')` / `@yield('scripts')`: un `@section` accetta un solo contributo, `@push` li somma.
- Niente meta, CSS o JS scritti direttamente nel layout.

Verifica: `scripts/check-layout.sh` · Template: `templates/views/layouts/main.blade.php`
