{{-- Maintenance page (503, `php artisan down`): rendered by the core Handler before Front::loadSharedContent(), with no
     data. It must stand alone: only translations, no facades, no layout, no libraries, no third-party fonts.
     The English block repeats the message for visitors of the other languages. --}}
<!DOCTYPE html>
<html lang="{{ app()->getLocale() }}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="robots" content="noindex">
  <title>@lang('front::maintenance.meta_title')</title>
  <link href="/assets/main/css/maintenance.css" rel="stylesheet">
</head>
<body class="maintenance">
  <main class="maintenance-card">
    {{-- Logo: a static <picture> with the webp (no <x-picture-webp>: components and facades are not available here) --}}
    <h1 class="maintenance-title">@lang('front::maintenance.title')</h1>
    <p>@lang('front::maintenance.text')</p>
    <p>@lang('front::maintenance.back_soon')</p>
    @if(app()->getLocale() !== 'en')
      <hr>
      <div class="maintenance-en" lang="en">
        <h2 class="maintenance-title">@lang('front::maintenance.title', [], 'en')</h2>
        <p>@lang('front::maintenance.text', [], 'en') @lang('front::maintenance.back_soon', [], 'en')</p>
      </div>
    @endif
  </main>
</body>
</html>
