<!DOCTYPE html>
<html lang="{{ Websites::currentLanguage('iso_code2') }}">
  <head>
    {{-- Head --}}
    @include('partials.base.head')
    @stack('styles')
  </head>
  <body class="lang-{{ Websites::currentLanguage('iso_code2') }} route-{{ Front::currentRouteName() }}">
    {{-- Skip link: first element of the page, visible only when it takes the keyboard focus --}}
    <a href="#main" class="visually-hidden-focusable skip-link">@lang('front::general.skip_to_content')</a>

    {{-- Header --}}
    @include('partials.header')

    {{-- Content --}}
    <main class="main" id="main">
      @yield('content')
    </main>

    {{-- Footer --}}
    @include('partials.footer')

    {{-- Scripts --}}
    @include('partials.base.scripts')
    @stack('scripts')
  </body>
</html>
