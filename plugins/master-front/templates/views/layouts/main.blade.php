<!DOCTYPE html>
<html lang="{{ Websites::currentLanguage('iso_code2') }}">
  <head>
    {{-- Head --}}
    @include('partials.base.head')
    @stack('styles')
  </head>
  <body class="lang-{{ Websites::currentLanguage('iso_code2') }} route-{{ Front::currentRouteName() }}">
    {{-- Header --}}
    @include('partials.header')

    {{-- Content --}}
    <main class="main">
      @yield('content')
    </main>

    {{-- Footer --}}
    @include('partials.footer')

    {{-- Scripts --}}
    @include('partials.base.scripts')
    @stack('scripts')
  </body>
</html>
