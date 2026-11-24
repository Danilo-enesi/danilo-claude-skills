<!-- Meta -->
{!! Meta::render() !!}
{!! Dom::renderCookieBanner() !!}

<!-- Preconnections -->
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

<!-- Fonts (blocked until cookie consent) -->
{!! Meta::googleFonts(
  'https://fonts.googleapis.com/css2?family=Open+Sans:wght@400;500;600;700&display=swap',
) !!}

<!-- Lib -->

<!-- Theme -->
@if(config('app.debug'))
    <link href="{{\Master\Facades\Version::get('/assets/common/beers/beers.css')}}" rel="stylesheet">
    <link href="{{\Master\Facades\Version::get('/assets/main/css/main.css')}}" rel="stylesheet">
    <link href="{{\Master\Facades\Version::get('/assets/main/css/responsive.css')}}" rel="stylesheet">
@else
    <link href="{{\Master\Facades\Version::get('/assets/main/css/base.min.css')}}" rel="stylesheet">
@endif

<!-- Icons -->
<link rel="shortcut icon" href="{{ \Master\Facades\Version::get('/favicon.ico') }}">
<link rel="apple-touch-icon" sizes="180x180" href="{{ \Master\Facades\Version::get('/assets/main/icons/icon-apple-180.png') }}">
<link rel="icon" type="image/png" sizes="192x192" href="{{ \Master\Facades\Version::get('/assets/main/icons/icon-192.png') }}">
<meta name="application-name" content="{{ Websites::current('description') }}">

<!-- Google tag (gtag.js) -->
@if(Websites::current('google_analytics_id') && !config('app.debug'))
  <script async data-epp-onconsent data-epp-category="10002" data-epp-src="https://www.googletagmanager.com/gtag/js?id={{ Websites::current('google_analytics_id') }}"></script>
  <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '{{ Websites::current('google_analytics_id') }}', { 'anonymize_ip': true });
  </script>
@endif
