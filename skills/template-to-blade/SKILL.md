---
name: template-to-blade
author: Danilo-enesi
description: Trasforma un HTML statico del prototipo di design (`template/*.html`, `template_storia/*.html`, `typo.html`, o un nuovo template consegnato) in una view Blade del front (`private/front/Main/Views/`). Attivala quando senti «migra il template», «porta questo HTML in Blade», «crea la pagina Storia/Contatti/…», «trasforma il prototipo in view», «integra il nuovo template», «converti l'HTML in Blade», o quando devi estrarre gli stili/JS di un HTML statico nel progetto. Ricorda: `template/` è la FONTE DI VERITÀ del design (sola lettura, markup/classi replicati 1:1) e nel Blade non si mette mai JS/CSS inline (CSS in `template/assets/css`, JS in `assets/js` + Mix).
---

# Skill: Migrazione template HTML → Blade

## Regola mentale n.1 — il `template/` è la FONTE DI VERITÀ del design (sola lettura)

Gli HTML statici (`template/*.html`, i nuovi consegnati come `template_storia/*.html`, e `typo.html`) sono il **prototipo di design approvato**. Quando migri:

- **Replica il markup e le classi CSS 1:1.** Nessuna classe inventata, nessuna omessa, nessuna "semplificazione". Il CSS esistente è agganciato a quei nomi classe: se cambi la struttura, rompi lo stile.
- **Non modificare i file dentro `template/*.html`** per farli combaciare col Blade: è il Blade che deve combaciare con loro.
- Se il markup del prototipo è palesemente sbagliato/incoerente, **segnalalo all'utente** invece di correggerlo di testa tua.

## Regola mentale n.2 — la view Blade contiene SOLO markup. Mai JS o CSS inline.

Questa è la regola non negoziabile del progetto (stesso principio del lato admin: JS/CSS mai inline nel form). Dentro una view Blade del front:

- ❌ Niente `<style>...</style>` nel corpo della view.
- ❌ Niente `<script>...</script>` con logica nel corpo della view.
- ❌ Niente `style="..."` inline (salvo variabili dinamiche brevi, es. `style="--i:{{ $index }}"`).
- ✅ Gli **stili** vanno nei file CSS di `template/assets/css/` (vedi Regola n.3).
- ✅ Il **JS** va in `template/assets/js/main.js` (o in una lib dedicata) e viene ricompilato con Mix.
- ✅ Il markup HTML va nel Blade (view di pagina, partial o componente).

## Regola mentale n.3 — estrazione CHIRURGICA degli stili, MAI sovrascrivere

Il nuovo template porta con sé un suo `assets/css/style.css` / `pages.css`. Questi file **quasi sicuramente differiscono** da quelli live del progetto. **Non copiare mai un intero file CSS sopra quello del progetto**: cancelleresti gli stili di tutte le altre pagine già migrate.

Procedura corretta:
1. Individua quali **classi/selettori** usa davvero l'HTML che stai migrando (le classi che compaiono nel markup di quella pagina).
2. Da `template_storia/assets/css/*.css` **estrai solo quelle regole** (blocco per blocco, incluse eventuali media query e keyframe collegati).
3. **Aggiungile** ai file CSS del progetto (`template/assets/css/`), sotto una sezione commentata dedicata (es. `/* === STORIA === */`), senza toccare le regole esistenti.
4. Se una regola ha lo **stesso selettore** di una già presente, NON sovrascrivere alla cieca: confronta, e se il design è cambiato aggiorna consapevolmente segnalando il diff all'utente.

### Dove vivono gli stili (e la pipeline Mix)

```
template/assets/css/
├── style.css      → stili globali + componenti riusabili (header, footer, blocchi, sezioni comuni)
├── pages.css      → stili SPECIFICI di singole pagine
└── base.min.css   → ARTEFATTO GENERATO da `npx mix` — NON editarlo mai a mano
```

`webpack.mix.js` concatena `beers.css + style.css + pages.css → base.min.css` (e `beers.js + main.js → base.min.js`).

- **Debug** (`config('app.debug')` true): `head.blade.php` carica `style.css` sorgente; `scripts.blade.php` carica `main.js` sorgente. → le tue modifiche si vedono subito.
- **Produzione**: si carica `base.min.{css,js}`. → **devi ricompilare**: da `private/` esegui `npx mix` (o `npx mix --production`).

Regola pratica: stile di un **componente riusabile** → `style.css`. Stile di una **singola pagina** → `pages.css`. Dopo aver toccato il CSS/JS, ricompila con Mix.

## Struttura del front (dove mettere il markup)

App MVC in `private/front/Main/` (vedi CLAUDE.md). Per la migrazione contano:

```
Views/
├── base/       layout.blade.php (scheletro), head.blade.php (CSS), scripts.blade.php (JS),
│               header/footer/offcanvas
├── pages/      una view per pagina (home, contacts, news, section-page, …)
├── partials/   frammenti riusabili inclusi con @include
└── components/ view dei componenti Blade (x-...)
Components/      classe PHP di ogni componente (PascalCase → x-kebab-case)
```

### Come si aggancia una view di pagina

Ogni pagina `@extends('base.layout')` ed espone due sezioni chiave del layout:

| Nel layout | A cosa serve | Come lo usi nella pagina |
|---|---|---|
| `@yield('head')` | CSS specifico di pagina | `@section('head') <link href="{{\Master\Facades\Version::get('/template/assets/css/pages.css')}}" rel="stylesheet"> @endsection` |
| `@yield('content')` | corpo pagina | `@section('content') …markup… @endsection` |
| `@stack('scripts')` | JS specifico di pagina | in un partial: `@push('scripts') <script src="{{\Master\Facades\Version::get('/template/assets/js/…')}}"></script> @endpush` |

**Sempre** `\Master\Facades\Version::get('/path')` per gli asset locali (cache-busting), mai un path nudo.

## Quando creare un COMPONENTE riusabile (vs partial vs markup inline)

Decisione in tre livelli:

1. **Markup inline nella view di pagina** — se il pezzo è unico di quella pagina e non si ripete. Es. l'intro testuale della Storia.

2. **Partial (`@include('partials.xyz')`)** — se il pezzo si ripete **identico** su più pagine e **non** ha bisogno di parametri/logica (o solo di variabili già in scope). Es. una fascia statica, un blocco di intestazione fisso.

3. **Componente Blade (`x-...`)** — crealo quando **almeno una** è vera:
   - lo stesso blocco compare su ≥2 pagine **con contenuti diversi** (immagine, titolo, link cambiano) → serve parametrizzazione;
   - ha una **API di props chiara** (es. una card, una sezione feature, un carosello, un header di pagina con varianti);
   - contiene **logica di presentazione** (default, condizioni, mapping) che non vuoi duplicare;
   - replica un elemento del design system (i blocchi di `typo.html`, la `page-header`, gli slider).

   Guarda gli esempi esistenti: `FeatureSection`, `CtaSection`, `ParallaxSection`, `NewsStrip`, `ProjectsSlider`, `SectionSidemenu`, `PageHeader`, `PictureWebP`. Sono la fonte del pattern.

> In dubbio: se lo useresti **una volta sola e senza parametri**, NON creare un componente. Il costo di un componente si ripaga con il riuso o la parametrizzazione. Non trasformare ogni `<section>` in un componente.

### Come si crea un componente (pattern del progetto)

1. Classe PHP in `private/front/Main/Components/NomeComponente.php`:
   ```php
   namespace Front\Main\Components;
   use Illuminate\View\Component;

   class NomeComponente extends Component
   {
       public function __construct(
           public string $title,
           public ?string $link = null,
           public $image = null,
       ) {}

       public function render() { return view('components.nome-componente'); }
   }
   ```
2. View in `private/front/Main/Views/components/nome-componente.blade.php` — **solo markup**, usa le props (`{{ $title }}`, ecc.).
3. Uso in pagina: `<x-nome-componente :title="$x" :link="$url" />`.
4. Gli stili del componente → `style.css` (è riusabile), replicati dalle classi del prototipo.

## Flusso di lavoro (checklist di migrazione)

Dato un HTML statico da migrare (es. `template_storia/storia.html`):

1. **Leggi l'HTML** e individua le macro-sezioni (`<section>`), le classi usate, gli asset (immagini, video), e gli eventuali comportamenti JS.
2. **Confronta con l'esistente**: la pagina rientra in un tipo già gestito (`section-page`, `news`, `contacts`…)? Alcune sezioni sono già coperte da componenti esistenti (`x-page-header`, `x-feature-section`…)? Riusa prima di ricreare.
3. **Decidi il partizionamento**: cosa resta inline, cosa diventa partial, cosa diventa componente (Regola sui componenti sopra).
4. **Crea la view di pagina** in `Views/pages/` che `@extends('base.layout')`, con `@section('content')`. Aggancia la rotta se serve (vedi `Routes/web.php`, raggruppate per locale).
5. **Sposta il markup** replicando le classi 1:1. Nessun `<style>`/`<script>` inline.
6. **Estrai gli stili chirurgicamente** dai CSS del nuovo template dentro `style.css`/`pages.css` (Regola n.3). Carica il CSS di pagina via `@section('head')` se non è già nel bundle.
7. **Sposta il JS** (se c'è) in `main.js`/lib dedicata; agganciato via `@push('scripts')` se è per una sola pagina.
8. **Sposta gli asset** (immagini, video) sotto `template/assets/…` con path serviti da `Version::get()`. Per le immagini valuta `<x-picture-web-p>`.
9. **Ricompila**: da `private/` → `npx mix`.
10. **Verifica dal vivo** sul front (skill `front-navigation`): la pagina deve essere identica al prototipo. Confronta a video con l'HTML statico.

## Errori da evitare

- ❌ Copiare un intero `style.css`/`pages.css` del nuovo template sopra quelli del progetto. ✅ Estrarre solo le regole delle classi usate da quella view.
- ❌ `<style>` o `<script>` con logica dentro il Blade. ✅ CSS in `assets/css`, JS in `assets/js`, poi Mix.
- ❌ Editare `base.min.css` / `base.min.js` a mano. ✅ Sono generati: modifica i sorgenti e lancia `npx mix`.
- ❌ Inventare/semplificare classi o struttura rispetto al prototipo. ✅ Replica 1:1 — il CSS dipende da quei nomi.
- ❌ Trasformare ogni sezione in un componente. ✅ Componente solo se riusato o parametrizzato; altrimenti inline o partial.
- ❌ Path asset nudi (`/template/assets/…`). ✅ Sempre `\Master\Facades\Version::get(...)` per il cache-busting.
- ❌ Dimenticare di ricompilare Mix → in produzione non si vedono le modifiche a CSS/JS.
- ❌ Ricreare da zero un blocco già coperto da un componente esistente o dai blocchi di `typo.html` (vedi skill `master-page-content`).
