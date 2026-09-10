# Riferimento — Esempio completo e commentato di layout front

Walkthrough di un layout front **reale e funzionante** (progetto Ovest Sesia, `private/front/Main/`),
usato come caso di studio delle regole in `SKILL.md`. Serve per:

* vedere le regole applicate insieme, in codice vero, invece che a frammenti;
* confrontare il layout del progetto su cui stai lavorando con un riferimento noto-buono;
* capire *perché* una regola esiste, con la trappola concreta che evita.

⚠️ È un **esempio**, non un template da copiare a occhi chiusi: nomi di partial, categorie PID,
librerie e campi Websites cambiano da progetto a progetto. La fonte di verità delle regole è
`SKILL.md`; la fonte di verità delle API è il vendor del progetto corrente
(`private/vendor/enesisrl/laravel-master-core/src/Foundation/`).

---

## 1. I file e il loro confine

```
private/front/Main/Views/base/
├── layout.blade.php     scheletro html + meta + cookie banner + window.front
├── head.blade.php       TUTTO ciò che va in <head>: preconnect, favicon, font, CSS
├── scripts.blade.php    TUTTO ciò che va prima di </body>: librerie JS + bundle
├── header.blade.php     markup header      ┐
├── offcanvas.blade.php  markup menu mobile ├─ dati iniettati da NavigationComposer
└── footer.blade.php     markup footer      ┘
```

Il confine è: **`layout.blade.php` non contiene asset propri, li include.** Se ti trovi ad
aggiungere un `<link>` o uno `<script>` dentro `layout.blade.php`, stai sbagliando file.

### `layout.blade.php` (struttura reale, semplificata)

```blade
<!DOCTYPE html>
<html lang="{{ Websites::currentLanguage('iso_code2') }}">
<head>
    {!! Meta::render() !!}              {{-- 1. meta/title/og/canonical/robots --}}
    {!! Dom::renderCookieBanner() !!}   {{-- 2. SDK EPP: PRIMA di ogni script bloccato --}}

    <meta name="csrf-token" content="{{ csrf_token() }}" />

    @include('base.head')               {{-- 3. CSS e asset di head del progetto --}}
    @stack('head')                      {{-- 4. head aggiuntivo di pagine e componenti --}}
</head>
<body class="lang-{{ Websites::currentLanguage('iso_code2') }} route-{{ Front::currentRouteName() }} theme-{{ Websites::current('theme.assets') }}">
    @include('base.offcanvas')
    @include('base.header')

    <main role="main">
        @yield('content')
    </main>

    @include('base.footer')

    {{-- unica config globale per il JS --}}
    <script>
        window.front = {
            route: '{{ Front::currentRouteName() }}',
            lang: '{{ App::getLocale() }}',
            google_api_key: '{{ Websites::current('google_api_key') }}',
            debug: @bool(config('app.debug', true)),
            env: '{{ config('app.env', 'local') }}',
        }
        @if(Cache::has('translations_front_' . App::getLocale()))
            window.front.translations = {!! Cache::get('translations_front_' . App::getLocale()) ?? "''" !!};
        @endif
    </script>

    @include('base.scripts')            {{-- librerie + bundle --}}
    @stack('scripts')                   {{-- JS specifico della singola pagina --}}
</body>
</html>
```

Da notare:

* le classi sul `<body>` (`lang-`, `route-`, `theme-`) sono **il gancio CSS/JS per-pagina**:
  evitano di dover iniettare CSS condizionale nelle viste (`body.route-contatti .map { … }`);
* `window.front` è **l'unico** punto in cui PHP passa valori al JS. Un componente che ha bisogno
  di un dato lato JS lo aggiunge qui o lo mette in un `data-*` sul proprio markup;
* le traduzioni front arrivano dalla cache, non da un endpoint: se mancano lato JS, il problema
  è la cache, non il layout.

---

## 2. `head.blade.php` — solo `<head>`, in ordine

```blade
<link rel="preconnect" href="https://cdn.ene.si">
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>

<!-- Favicon -->
<link rel="icon" href="/assets/main/favicon.ico" sizes="any">
<link rel="icon" type="image/svg+xml" href="{{ \Master\Facades\Version::get('/template/assets/img/logo.svg') }}">

<!-- Google Fonts (già bloccati per il consenso, categoria 10003) -->
{!! Meta::googleFonts('https://fonts.googleapis.com/css2?family=Playfair+Display:…&display=swap') !!}

<!-- Librerie CSS -->
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
<link href="{{ \Master\Facades\Version::get('/template/assets/lib/aos/aos.css') }}" rel="stylesheet">
<link href="//cdn.ene.si/slick/1.8.1/slick.css" rel="stylesheet">

<!-- CSS del progetto: sorgenti in debug, bundle minificato in produzione -->
@if(config('app.debug'))
   <link href="{{ \Master\Facades\Version::get('/template/assets/css/style.css') }}" rel="stylesheet">
@else
   <link href="{{ \Master\Facades\Version::get('/template/assets/css/base.min.css') }}" rel="stylesheet">
@endif

<!-- Google Analytics: loader BLOCCATO, categoria statistiche -->
@if(Websites::current('google_analytics_id') && !config('app.debug'))
   <script data-epp-onconsent data-epp-category="10002"
           data-epp-src="https://www.googletagmanager.com/gtag/js?id={{ Websites::current('google_analytics_id') }}"></script>
   <script>
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '{{ Websites::current('google_analytics_id') }}', { 'anonymize_ip': true });
   </script>
@endif
```

Ordine che conta: `preconnect` per primi (aprono la connessione mentre il resto scarica), poi
font, poi librerie, poi il CSS del progetto **per ultimo** (deve poter sovrascrivere Bootstrap).

Sull'ultimo blocco: il *loader* di GA è bloccato, l'inline `gtag('config', …)` no. Regge perché
`gtag` accoda i comandi nel `dataLayer` e il Consent Mode v2 lo imposta l'SDK EPP; **qualsiasi
altro** tracciamento inline però va bloccato con `data-epp-onconsent type="text/plain"`.

---

## 3. `scripts.blade.php` — solo fine `</body>`

```blade
<!-- Librerie -->
<script src="https://code.jquery.com/jquery-3.7.1.min.js" …></script>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
<script src="{{ \Master\Facades\Version::get('/template/assets/lib/aos/aos.js') }}"></script>
<script src="//cdn.ene.si/slick/1.8.1/slick.min.js"></script>

<!-- Codice del progetto -->
@if(config('app.debug'))
   <script src="{{ \Master\Facades\Version::get('/template/assets/js/main.js') }}"></script>
@else
   <script src="{{ \Master\Facades\Version::get('/template/assets/js/base.min.js') }}"></script>
@endif
```

Le librerie stanno **prima** del codice del progetto, e tutto sta **prima** di `@stack('scripts')`:
così il JS di pagina trova jQuery, Bootstrap e slick già inizializzabili senza `defer`/listener
di comodo.

---

## 4. Estendere il layout da una pagina

```blade
{{-- Views/pages/contatti.blade.php --}}
@extends('base.layout')

@push('head')
    <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" crossorigin="">
    <link href="{{ \Master\Facades\Version::get('/template/assets/css/contatti.css') }}" rel="stylesheet">
@endpush

@section('content')
    …
@endsection

@push('scripts')
    <script src="{{ \Master\Facades\Version::get('/template/assets/js/contatti.js') }}"></script>
@endpush
```

Entrambi gli hook sono **stack**, non `@yield`: se domani un Blade component della pagina deve
aggiungere il suo CSS, con `@section('head')` cancellerebbe quello della pagina, con `@push('head')`
si somma. Nei component ripetibili si usa `@pushOnce('head', 'chiave')`.

Perché `@push` e non uno `<script>` dentro `@section('content')`: nel content lo script gira
**prima** che le librerie siano caricate e finisce in mezzo al markup, dove nessuno lo cerca.

Se il comportamento serve a più di una pagina, non va in un file per-pagina: va in
`template/assets/js/` e dentro il bundle Mix (`webpack.mix.js`), attivato dalla classe
`route-*` sul body o da un `data-*` sul markup.

---

## 5. Meta dal controller

```php
// Front/Main/Controllers/PagesController.php

// pagina statica: stringhe da traduzione
Meta::set('title',       __('front::contacts_page.meta_title'));
Meta::set('description', __('front::contacts_page.meta_desc'));

// contenuto dal CMS: campo meta con fallback sul testo
Meta::set('title',       $post->meta_title ?: $post->description);
Meta::set('description', $post->meta_description ?: $post->summary);
Meta::set('canonical',   $post->url);
Meta::set('og:image',    $post->cover?->getFullUrl());
```

Il pattern `meta_title ?: description` è quello giusto: l'admin compila il campo meta solo quando
vuole discostarsi dal titolo, e la pagina non resta senza `<title>` nel frattempo.

Su liste paginate, il `canonical` va costruito a mano dalla pagina corrente (nel progetto esiste
un `buildPaginatedCanonical()` nel controller): altrimenti `?page=2` eredita il canonical di
pagina 1 e le pagine successive risultano duplicate.

---

## 6. Dati condivisi: il caso menu / social / footer

Tre viste (`header`, `offcanvas`, `footer`) hanno bisogno degli stessi dati. Soluzione applicata:

```php
// app/Providers/FrontServiceProvider.php
class FrontServiceProvider extends \Enesisrl\LaravelMasterCore\Providers\FrontServiceProvider
{
    public function register()
    {
        parent::register();

        // Condiviso fra le tre viste servite da NavigationComposer: legge
        // sezioni, pagine e categorie una sola volta per richiesta.
        $this->app->singleton(MenuBuilder::class);
    }

    public function boot()
    {
        parent::boot();

        View::composer(['base.header', 'base.offcanvas', 'base.footer'], NavigationComposer::class);

        // …registrazione dei Blade component, @routeIs, @svg
    }
}
```

```php
// Front/Main/Classes/NavigationComposer.php
class NavigationComposer
{
    public function __construct(private MenuBuilder $menus) {}

    public function compose(View $view): void
    {
        $view->with([
            'socials'           => Websites::current('social'),
            'externalLinks'     => Link::prepare(['published' => true, 'lang' => App::getLocale()])
                                        ->orderBy('sequence')->get(),
            'headerSections'    => $this->menus->build('header'),
            'footerSections'    => $this->menus->build('footer'),
            'offcanvasSections' => $this->menus->build('offcanvas'),
        ]);
    }
}
```

La trappola che il **singleton** evita: `compose()` viene chiamato **una volta per vista**, quindi
tre volte per richiesta. Senza `singleton(MenuBuilder::class)`, ogni chiamata istanzia un builder
nuovo e le query sui menu girano ×3. Con il singleton, la prima chiamata popola lo stato interno e
le altre due lo riusano.

La seconda scelta importante: il composer è registrato su un **elenco esplicito** di viste, non su
`'*'`. Su `'*'` i menu verrebbero calcolati anche per le view delle API e delle mail.

Nel footer, i link informativa sono attributi EPP, non route:

```blade
<a href="#" class="footer-policy-link" data-epp="policy">{{ __('front::footer.privacy_policy') }}</a>
<a href="#" class="footer-policy-link" data-epp="cookie">{{ __('front::footer.cookie_policy') }}</a>
```

---

## 7. Blocco di un embed dentro un componente

```blade
{{-- partials/hero-carousel.blade.php --}}
<div class="hero-bg" data-epp-autolock data-epp-category="10003">
    <iframe src="https://www.youtube.com/embed/…"></iframe>
</div>
```

`data-epp-autolock` sul **contenitore** è la scelta giusta quando gli iframe sono generati in un
ciclo su dati CMS: non serve toccare il markup interno di ogni slide, e nuovi video aggiunti
dall'admin nascono bloccati per costruzione.

---

## 8. Checklist di confronto

Da usare quando entri in un progetto Master e vuoi capire se il layout è a norma:

* [ ] `Meta::render()` è la prima cosa in `<head>`? Ci sono `<title>`/`<meta>` scritti a mano in giro?
* [ ] `Dom::renderCookieBanner()` è **prima** di ogni risorsa bloccata? `epp_policy_id` è valorizzato sul Website?
* [ ] `head.blade.php` contiene solo roba da `<head>` e `scripts.blade.php` solo roba da fine body?
* [ ] Il layout espone `@stack('head')` e `@stack('scripts')`? Ci sono `@yield('head')` / `@section('head')` residui da convertire in `@push`?
* [ ] `grep -rn "<script" Views/pages Views/partials Views/components` restituisce qualcosa? Ogni occorrenza va giustificata o spostata.
* [ ] Gli asset locali passano tutti da `Version::get()`? Lo split debug/prod è coerente fra head e scripts?
* [ ] I nuovi file JS/CSS sono dichiarati in `webpack.mix.js`?
* [ ] Google Fonts passa da `Meta::googleFonts()`?
* [ ] Ogni script/iframe/link di terze parti ha `data-epp-onconsent`/`data-epp-src`/`data-epp-href` con la sua categoria?
* [ ] Ci sono query o accessi a Model dentro le Blade? Vanno in un view composer o in `loadSharedContent()`.
* [ ] Le classi che fanno query per un composer registrato su più viste sono singleton?
* [ ] Ogni action che rende una pagina imposta `title` e `description`?
* [ ] Dopo le modifiche: `php artisan optimize` (da `private/`) e `npx mix --production` se hai toccato gli asset.
