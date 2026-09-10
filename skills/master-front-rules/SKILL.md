---
name: master-front-rules
description: Regole di setup del LAYOUT del front nei progetti Master Laravel Enesi (`private/front/Main/Views/base/`) — separazione head/footer, i due stack `@stack('head')` / `@stack('scripts')`, classi `lang-`/`route-`/`theme-` sul body, `Meta::render()` e `Meta::set()`, `Dom::renderCookieBanner()`, blocco preventivo degli script che richiedono il consenso cookie (attributi `data-epp-*`), e condivisione dati cross-Blade via view composer o `Front::loadSharedContent()` + `Dom::config()`. Attivala quando senti «imposta/rifattorizza il layout del front», «head/scripts blade», «dove metto questo script/CSS», «meta tag / SEO / title / og:image», «cookie banner», «EPP / privacy.ene.si», «script bloccato fino al consenso», «Google Analytics/Fonts/Maps/YouTube nel front», «questo dato serve in header e footer», «view composer», «dati condivisi fra le view». Ricorda: nelle Blade NON si scrive mai JS/CSS inline, i meta non si scrivono a mano, e ogni risorsa di terze parti nasce BLOCCATA.
---

# Skill: Regole del layout del front (Master Laravel Enesi)

Quattro regole mentali, in ordine di importanza. Il resto della skill le spiega.

1. **Il layout non contiene asset propri**: include `base.head` (solo `<head>`) e `base.scripts` (solo fine `</body>`). Nelle viste di pagina/partial/componente non esiste JS o CSS inline.
2. **I meta non si scrivono a mano**: `Meta::render()` li stampa tutti, i valori si impostano dal controller con `Meta::set()`.
3. **Ogni risorsa di terze parti nasce bloccata**: `Dom::renderCookieBanner()` + attributi `data-epp-*`. Includere uno script esterno "normalmente" è un bug di compliance, non una scorciatoia.
4. **Un dato che serve a più Blade si carica una volta sola, in un posto solo.** Due meccanismi, entrambi convenzione del progetto: **view composer** per i dati di alcune viste, **`Front::loadSharedContent()` + `Dom::config()`** per i dati globali del front (§4). Mai query dentro le Blade, mai lo stesso array ricalcolato in ogni controller.

## Materiale di supporto

* `references/epp-cookie-banner.md` — catalogo completo del cookie banner EPP: attributi di blocco, pulsanti `data-epp`, API JS, categorie PID, eccezioni.
* `references/layout-esempio-commentato.md` — walkthrough di un layout reale e funzionante (head, scripts, meta, composer, embed bloccati) con le trappole che ogni scelta evita, più una checklist di confronto per entrare in un progetto esistente.

---

## 0. Prima di toccare qualcosa: verifica le API sul progetto

L'ecosistema è versionato per progetto (`private/vendor/enesisrl/laravel-master-core`) e **non tutti i metodi esistono in tutte le versioni**. Prima di usare un helper che non hai visto in questo repo, controlla:

```
private/vendor/enesisrl/laravel-master-core/src/Foundation/Meta.php
private/vendor/enesisrl/laravel-master-core/src/Foundation/Dom.php
private/vendor/enesisrl/laravel-master-core/src/Foundation/Front.php
```

Metodi che **esistono** e vanno usati (verificati su 8 progetti Master): `Meta::render()`, `Meta::set()`, `Meta::append()`, `Meta::get()`, `Meta::format()`, `Meta::googleFonts()`, `Dom::renderCookieBanner()`, `Dom::config()`, `Dom::format_address()`, `Dom::phone_number_format()`, `Front::route()`/`routeLang()`/`globalRoute()`, `Front::currentRouteName()`, `Front::running()`, `Front::groupRoutes()`, `Front::loadSharedContent()` (stub da implementare, §4.2), `Version::get()`.

Non inventare helper "simmetrici" che sembrano esistere ma non esistono: per gli script di terze parti si usano gli attributi `data-epp-*` (§3.2), per i Google Fonts `Meta::googleFonts()` (§2), e non c'è nessun `Meta::script()`.

**Punto di estensione corretto**: le facade `Meta`, `Dom`, `Front`, `Version`, `Admin`, `Tool` sono bindate come singleton su `Master\Foundation\*`, cioè su **`private/master/Foundation/*.php`** — codice di progetto, non vendor, di norma sottoclassi vuote pronte a essere estese. Il vendor non si modifica mai: le modifiche condivise vanno nel repo `laravel-master-dev` e rientrano via Composer.

---

## 1. Anatomia del layout e separazione head / footer

```
private/front/Main/Views/base/
├── layout.blade.php     scheletro + Meta::render() + cookie banner + window.front
├── head.blade.php       TUTTO ciò che va in <head>: preconnect, favicon, font, CSS
├── scripts.blade.php    TUTTO ciò che va prima di </body>: librerie JS + bundle
├── header.blade.php     ┐
├── offcanvas.blade.php  ├─ markup, dati iniettati da un view composer (§4.1)
└── footer.blade.php     ┘
```

```blade
<!DOCTYPE html>
<html lang="{{ Websites::currentLanguage('iso_code2') }}">
<head>
    {!! Meta::render() !!}              {{-- 1. meta/title/og/canonical/robots --}}
    {!! Dom::renderCookieBanner() !!}   {{-- 2. SDK EPP: PRIMA di ogni risorsa bloccata --}}

    @include('base.head')               {{-- 3. CSS/asset di head del progetto --}}
    @stack('head')                      {{-- 4. head aggiuntivo di pagine e componenti --}}
</head>
<body class="lang-{{ Websites::currentLanguage('iso_code2') }} route-{{ Front::currentRouteName() }} theme-{{ Websites::current('theme.assets') }}">
    @include('base.offcanvas')
    @include('base.header')

    <main role="main">@yield('content')</main>

    @include('base.footer')

    <script>window.front = { … }</script>  {{-- unica config globale per il JS --}}

    @include('base.scripts')            {{-- librerie + bundle --}}
    @stack('scripts')                   {{-- JS aggiuntivo di pagine e componenti --}}
</body>
</html>
```

**Due stack, `head` e `scripts` — mai `@yield`/`@section`.** `@stack('head')` in `<head>` (CSS,
preload, meta extra, JSON-LD), `@stack('scripts')` prima di `</body>`. Motivo: `@yield`/`@section`
accetta **un solo** contributo, quindi due viste o componenti che usano lo stesso hook si annullano a
vicenda (vince l'ultimo) e un Blade component non può contribuire affatto. `@push`/`@stack`
**accumula** e funziona da pagine, partial e component; `@pushOnce` evita il doppio inserimento
quando lo stesso componente compare più volte nella pagina.

**Ordine non negoziabile**: `@stack('head')` **dopo** `@include('base.head')` (la pagina può
sovrascrivere il CSS globale); `@stack('scripts')` **dopo** `@include('base.scripts')`
(jQuery/Bootstrap/slick sono già disponibili quando gira il JS di pagina).

**Classi sul `<body>`** — convenzione, sono il gancio CSS/JS per non scrivere codice condizionale
nelle viste:

| Classe                  | Da                                        | Serve a                                       |
| ----------------------- | ----------------------------------------- | --------------------------------------------- |
| `lang-it`, `lang-en`, …  | `Websites::currentLanguage('iso_code2')`  | ritocchi tipografici e di layout per lingua   |
| `route-contatti`, …     | `Front::currentRouteName()`               | stile e attivazione JS per pagina             |
| `theme-…`               | `Websites::current('theme.assets')`       | varianti di tema nei progetti multi-sito      |

```css
body.lang-de .nav-link { letter-spacing: 0; }   /* parole lunghe */
body.route-contatti .map { display: block; }
```

Il nome della rotta arriva già senza prefisso dominio/lingua, quindi `route-*` è stabile fra le
lingue: la stessa regola CSS vale per `/it/contatti` e `/en/contacts`.

### Cosa va dove

| Serve…                                | Va in…                                                     |
| ------------------------------------- | ---------------------------------------------------------- |
| CSS a tutto il sito                   | `base/head.blade.php`                                      |
| JS a tutto il sito                    | `base/scripts.blade.php` (fine body, **non** in head)      |
| CSS/JS di **una** pagina o componente | `@push('head')` / `@push('scripts')`                       |
| Valore da passare al JS               | `window.front` nel layout, o `data-*` sul markup           |
| Comportamento riusabile               | file in `template/assets/js/` incluso nel bundle Mix       |

```blade
{{-- Views/pages/contatti.blade.php --}}
@push('head')
    <link href="{{ \Master\Facades\Version::get('/template/assets/css/contatti.css') }}" rel="stylesheet">
@endpush

@push('scripts')
    <script src="{{ \Master\Facades\Version::get('/template/assets/js/contatti.js') }}"></script>
@endpush
```

In un Blade component che può comparire più volte nella stessa pagina, usa `@pushOnce` con una
chiave, così l'asset entra una volta sola:

```blade
{{-- Views/components/blocks/photogallery.blade.php --}}
@pushOnce('head', 'lightbox')
    <link href="{{ \Master\Facades\Version::get('/template/assets/lib/lightbox/lightbox.css') }}" rel="stylesheet">
@endPushOnce
```

Se un progetto usa ancora `@yield('head')`, va migrato a `@stack('head')`: nella transizione si
possono tenere entrambi (`@stack('head')` subito dopo `@yield('head')`) finché tutte le
`@section('head')` non sono diventate `@push('head')`.

**Perché**: l'ordine di caricamento resta in un punto solo; il codice condiviso finisce nel bundle minificato invece di essere duplicato per pagina; quando cambia una libreria si tocca un file, non venti viste.

### Asset: `Version::get()` e split debug/produzione

Asset locali **sempre** dentro `\Master\Facades\Version::get()` (cache busting), e split ambiente già convenzionale in `head`/`scripts`:

```blade
@if(config('app.debug'))
   <link href="{{ \Master\Facades\Version::get('/template/assets/css/style.css') }}" rel="stylesheet">
@else
   <link href="{{ \Master\Facades\Version::get('/template/assets/css/base.min.css') }}" rel="stylesheet">
@endif
```

I `.min.*` li produce laravel-mix (`npx mix --production` da `private/`, config in `webpack.mix.js`): **non si editano a mano**. Se hai aggiunto un file JS/CSS nuovo, verifica che sia concatenato in `webpack.mix.js`, altrimenti in produzione non esiste.

Per portare un HTML del prototipo in Blade estraendo correttamente stili e script → vedi la skill `template-to-blade`.

---

## 2. `Meta::render()` — meta tag centralizzati

`Meta::render()` in `<head>` stampa **tutta** la mappa: `charset`, `viewport`, `title`, `description`, `canonical`, `robots`, blocco OpenGraph, blocco Twitter, App Links. **Nessuno di quei tag si scrive a mano in una vista.**

I valori si impostano **nel controller**, prima del `return view(...)`:

```php
Meta::set('title',       $post->meta_title ?: $post->description);
Meta::set('description', $post->meta_description ?: $post->summary);
Meta::set('canonical',   $post->url);
Meta::set('og:image',    $post->cover?->getFullUrl());
```

Comportamenti del core da NON reimplementare:

* **Fallback a catena**: `og:title`/`twitter:title` ← `title`; `og:description`/`twitter:description` ← `description`; `twitter:image` ← `og:image`; `canonical`/`og:url` ← `request()->fullUrl()`; `og:locale` ← lingua del sito; `og:type`/`twitter:card` ← `website`. Basta impostare `title` + `description` (+ `og:image` dove c'è una cover).
* `title`/`description` passano da `format()`: strip tag, newline rimosse, **troncamento a 160 caratteri**. Non troncare a mano.
* `robots` → `noindex, nofollow` **automatico** in ambiente `development`.
* `og:image`/`twitter:image`/`og:video` sono di tipo **array**: `set()` ripetuto **aggiunge** un tag; `null` resetta.
* URL relativi (`/storage/...`) completati con schema+host e **validati**: se non validi, il tag non viene emesso (utile da sapere quando un `og:image` "sparisce").
* `set()` accetta **solo** le chiavi mappate: una chiave sconosciuta ritorna `false` **in silenzio**. Per un meta nuovo (es. `theme-color`) si estende la mappa in `Master\Foundation\Meta`, non si stampa il tag nella vista.
* `Meta::googleFonts($url)` genera il `<link>` dei Google Fonts **già bloccato** per il consenso (`data-epp-href` + categoria `10003`). Usarlo sempre: mai un `<link href>` diretto a `fonts.googleapis.com`.

Regola operativa: **ogni action di controller che rende una pagina imposta `title` e `description`.** Se il dato viene dal CMS, usa il campo meta del model con fallback sul testo (`$model->meta_title ?: $model->description`).

---

## 3. `Dom::renderCookieBanner()` e il blocco preventivo

### 3.1 Il banner

```blade
{!! Dom::renderCookieBanner() !!}
```

Emette lo script dell'SDK EPP (`https://privacy.ene.si/api/js?uid=…&ln=…&key=…`) e ritorna `null` se il sito non è configurato. Legge dal modulo **Websites**:

| Campo             | Ruolo                                          |
| ----------------- | ---------------------------------------------- |
| `epp_policy_id`   | UID progetto — **se vuoto il banner non esce** |
| `ene_api_key`     | KEY cliente (opzionale)                        |
| lingua corrente   | `ln` in `iso_code3` (ita, eng, spa, …)         |

Posizione: **subito dopo `Meta::render()`, prima di qualunque risorsa bloccata**. È l'SDK che sblocca gli elementi: se arriva dopo, lo sblocco è tardivo. L'SDK inietta da sé il proprio CSS (non includere `privacy.ene.si/api/css`) e imposta da sé il **Google Consent Mode v2** se non trova già un comando `consent` nel `dataLayer`.

Primo controllo quando "il banner non si vede": `epp_policy_id` valorizzato sul Website corrente.

### 3.2 Bloccare le risorse che richiedono consenso

| Cosa                         | Come si blocca                                              |
| ---------------------------- | ----------------------------------------------------------- |
| Script esterno               | `data-epp-onconsent` + `src` → `data-epp-src`               |
| Script inline                | `data-epp-onconsent` + `type="text/plain"`                  |
| `<link>` (font, CSS 3rd)     | `href` → `data-epp-href`                                    |
| `<iframe>` (YouTube, Maps)   | `src` → `data-epp-src` (e `src="about:blank"`)               |
| Gruppo di iframe             | `data-epp-autolock` sull'elemento **contenitore**           |
| Categoria specifica          | `data-epp-category="PID"` su qualsiasi dei precedenti       |

PID ricorrenti: **`10002`** statistiche/analytics, **`10003`** miglioramento dell'esperienza (font, mappe, embed). Senza categoria lo sblocco avviene con l'accettazione generica.

Unica eccezione alla scrittura a mano: i **Google Fonts**, per cui esiste `Meta::googleFonts($url)` — genera il `<link>` già con `data-epp-href` e categoria `10003`. Usarlo sempre, anche per più URL insieme (`Meta::googleFonts($a, $b)`), invece di comporre l'attributo a mano. Per tutto il resto (script, iframe, altri CSS di terze parti) non esistono helper: si applicano gli attributi della tabella sopra.

```blade
{{-- Google Analytics: loader bloccato, categoria statistiche --}}
@if(Websites::current('google_analytics_id') && !config('app.debug'))
   <script data-epp-onconsent data-epp-category="10002"
           data-epp-src="https://www.googletagmanager.com/gtag/js?id={{ Websites::current('google_analytics_id') }}"></script>
@endif

{{-- gruppo di iframe/video --}}
<div class="hero-bg" data-epp-autolock data-epp-category="10003"> … </div>

{{-- script inline --}}
<script data-epp-onconsent data-epp-category="10003" type="text/plain">
    initMappaLeaflet();
</script>
```

**Trappole viste in produzione**

* Bloccare il loader di GA/GTM e lasciare l'inline `gtag('config', …)` non bloccato: tollerabile (i comandi si accodano nel `dataLayer` e il Consent Mode lo gestisce l'SDK), ma qualsiasi **altro** codice di tracciamento inline va bloccato.
* Un iframe con `data-epp-src` senza `src="about:blank"` in alcuni browser fa comunque una richiesta.
* Il pulsante `data-epp="accept-category"` si attiva **solo dopo** l'accettazione del banner.
* reCAPTCHA di norma **non** si blocca, per non rompere validazione e invio dei form.

Catalogo completo di attributi, pulsanti (`data-epp="accept|decline|policy|cookie|cookie-preferences|…"`) e API JS (`EPP.onAccept`, `EPP.loadScript`, `EPP.isAllowedCategory`, `EPP.allowCategory`) → `references/epp-cookie-banner.md`.

---

## 4. Dati condivisi fra Blade: due convenzioni

Per i dati cross-Blade esistono **due meccanismi, entrambi convenzione del progetto**. Non sono
alternative in competizione: coprono due esigenze diverse e nello stesso progetto convivono.

| | **View composer** (§4.1) | **`Front::loadSharedContent()` + `Dom::config()`** (§4.2) |
| --- | --- | --- |
| Copre | dati di **alcune** viste | dati **globali** a tutto il front |
| Il dato arriva come | variabile Blade (`$socials`) | `Dom::config('chiave')` |
| Costo | solo sulle viste registrate | ogni richiesta front (incluse le API) |
| Dipendenze | iniettabili nel costruttore | risolte a mano nel metodo |
| Punto di registrazione | `FrontServiceProvider::boot()` | `Master\Foundation\Front` + boot |
| Casi tipici | menu, social, footer, sidebar | contatto principale, impostazioni di sito, feature flag |

Criterio secco: **il dato è una variabile di *quelle* viste → composer; è un fatto del sito che
può servire a qualsiasi vista o componente → `loadSharedContent()`.** Se un dato serve a
header + footer, il composer è la strada; se serve a header, footer, 6 pagine e 3 componenti,
elencare le viste diventa fragile e va nel contenuto condiviso globale.

Anti-pattern (validi per entrambi):

* query o `Model::...` dentro le viste;
* lo stesso array (menu, social, contatti) ricalcolato in ogni controller e passato a `view()`;
* dati passati a `@include` a catena solo per far arrivare un valore a un partial in fondo.

Un dato che serve a **più** Blade si carica **una volta per richiesta, in un posto solo**.

### 4.1 View composer — dati di alcune viste

Ricetta da seguire ogni volta: **classe composer + classe builder singleton + registrazione su un
elenco esplicito di viste.**

```php
// app/Providers/FrontServiceProvider.php
public function register()
{
    parent::register();
    // Condiviso fra le tre viste servite dal composer:
    // legge sezioni/pagine/categorie una sola volta per richiesta.
    $this->app->singleton(MenuBuilder::class);
}

public function boot()
{
    parent::boot();
    View::composer(['base.header', 'base.offcanvas', 'base.footer'], NavigationComposer::class);
}
```

```php
class NavigationComposer
{
    public function __construct(private MenuBuilder $menus) {}

    public function compose(View $view): void
    {
        $view->with([
            'socials'           => Websites::current('social'),
            'externalLinks'     => $this->getExternalLinks(),
            'headerSections'    => $this->menus->build('header'),
            'footerSections'    => $this->menus->build('footer'),
            'offcanvasSections' => $this->menus->build('offcanvas'),
        ]);
    }
}
```

Due dettagli da replicare sempre:

1. Composer registrato su un **elenco esplicito di viste**, non su `*`: solo chi usa i dati ne paga il costo.
2. La classe che fa le query è un **singleton**: il composer viene invocato una volta per vista (qui 3), quindi senza singleton le query si triplicano.

Usa un composer quando: il dato serve a un insieme **identificabile** di viste, ha dipendenze da
iniettare, o vive naturalmente come variabile Blade (`$socials`, `$headerSections`). Vale anche per
una **singola** vista condivisa (header, footer, sidebar): meglio un composer che passare il dato da
ogni controller che rende quella vista.

Piccole regole di igiene:

* una classe composer per **area** (navigazione, sidebar, …), non una per variabile;
* le query stanno nel builder iniettato, non nel metodo `compose()`;
* il composer **non** deve poter fallire su dati mancanti: torna collection vuote, non `null`,
  così le Blade non hanno bisogno di `@isset` difensivi;
* mai `View::composer('*', …)`: colpisce anche le view di mail e API.

### 4.2 `Front::loadSharedContent()` + `Dom::config()` — dati globali al front

Il core espone l'hook `Front::loadSharedContent(): void` — **stub vuoto**, è il posto previsto per i
dati globali del front (spesso chiamato a voce "`Front::sharedContent`"; il metodo si chiama
`loadSharedContent`). Si implementa nella sottoclasse di progetto e si appoggia a `Dom::config()`,
lo store chiave/valore per-richiesta del core.

Vantaggi rispetto al composer, quando il dato è davvero globale: non serve mantenere l'elenco delle
viste (che si sfalda appena qualcuno aggiunge un partial), il valore è leggibile anche fuori dalle
Blade (componenti, `Notifications`, controller, mail) e non occupa un nome di variabile Blade che
una vista potrebbe sovrascrivere.

```php
<?php
// private/master/Foundation/Front.php

namespace Master\Foundation;

use Master\Facades\Dom;

class Front extends \Enesisrl\LaravelMasterCore\Foundation\Front
{
    public function loadSharedContent(): void
    {
        Dom::config('contatto_principale', Contact::prepare(['published' => true])->first());
    }
}
```

```php
// app/Providers/FrontServiceProvider.php — boot()
if (Front::running()) {
    Front::loadSharedContent();
}
```

Letto da qualsiasi Blade o componente: `Dom::config('contatto_principale')` — senza passaggi via `view()` né `@include`.

⚠️ Gira su **ogni** richiesta front, incluse le API: ci vanno dati **pochi, leggeri e davvero
globali**. Sintomi che il dato non appartiene qui: una query pesante o paginata, un valore che serve
a una sola pagina, o un `Dom::config()` letto da un solo Blade → è roba da composer o da controller.

I due meccanismi si combinano: nello stesso progetto il composer serve menu/social alle viste
`base.*`, e `loadSharedContent()` tiene il contatto principale e le impostazioni di sito a
disposizione di tutto il front.

### 4.3 Tabella di scelta

| Dato                                             | Dove                                            |
| ------------------------------------------------ | ----------------------------------------------- |
| Serve a viste identificabili (menu, social, footer…) | View composer + builder singleton           |
| Fatto globale del sito (contatti, settings…)     | `Front::loadSharedContent()` + `Dom::config()`  |
| Dato di una sola pagina                    | Controller → `view('…', [...])`                 |
| Dato di un solo blocco di markup           | Blade component (`Front\Main\Components\…`)     |
| Config per il JS                           | `window.front` nel layout                       |

---

## 5. Checklist (layout nuovo o rifattorizzato)

* [ ] `Meta::render()` come prima cosa in `<head>`; nessun `<title>`/`<meta>` a mano nelle viste.
* [ ] `Dom::renderCookieBanner()` subito dopo, prima di ogni risorsa bloccata.
* [ ] `epp_policy_id` (+ `ene_api_key`) valorizzati sul Website.
* [ ] `head.blade.php` = solo `<head>`; `scripts.blade.php` = solo fine `</body>`; **zero** JS/CSS inline nelle pagine.
* [ ] Il layout espone **due stack**, `@stack('head')` e `@stack('scripts')`; nessun `@yield('head')` residuo.
* [ ] Estensioni di pagine e componenti solo via `@push('head')` / `@push('scripts')` (`@pushOnce` nei component ripetibili).
* [ ] Asset locali sempre in `Version::get()`; split `config('app.debug')`; nuovi file dichiarati in `webpack.mix.js`.
* [ ] Google Fonts via `Meta::googleFonts()`.
* [ ] Ogni script/iframe/link di terze parti ha `data-epp-onconsent` / `data-epp-src` / `data-epp-href` + categoria.
* [ ] Privacy e cookie policy nel footer con `data-epp="policy"` / `data-epp="cookie"`.
* [ ] Nessuna query nelle Blade: view composer (con builder singleton) per i dati di alcune viste, `loadSharedContent()` + `Dom::config()` per i fatti globali del sito.
* [ ] Nessun `View::composer('*', …)`; la classe che fa le query per un composer multi-vista è singleton.
* [ ] `Meta::set('title')` e `Meta::set('description')` in **ogni** action che rende una pagina.
* [ ] Dopo modifiche a config/viste: `php artisan optimize` (da `private/`). Dopo modifiche agli asset: `npx mix --production`.
