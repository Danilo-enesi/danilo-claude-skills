# Regola: immagini, iframe e video che non rallentano la pagina

Tre misure di Core Web Vitals dipendono da come si caricano i media: **LCP** (quando compare l'elemento più grande in alto), **CLS** (quanto la pagina salta mentre carica), il peso scaricato su mobile. Tutte le immagini passano da `<x-picture-webp>` (`components-reuse.md`), che di default è `loading="lazy"` + `decoding="async"`.

## 1. L'immagine LCP: `priority`

L'immagine più grande visibile **senza scrollare** (hero della home, cover del dettaglio, prima slide) non deve essere lazy: il browser la scaricherebbe per ultima.

```blade
<x-picture-webp :image="$post->cover" conversion="cover" :alt="$post->title" priority width="1600" height="900" />
```

- `priority` → `loading="eager"` + `fetchpriority="high"`.
- **Una sola** per pagina: è la priorità, se tutto è prioritario niente lo è.
- Tutte le altre restano lazy (il default): non passare `loading="eager"` a mano.
- Se l'elemento LCP è uno **sfondo CSS** (hero con `background-image`), il browser lo scopre tardi: precaricalo dalla vista con `@push('styles')` e `<link rel="preload" as="image" href="..." fetchpriority="high">` (con `imagesrcset`/`imagesizes` se cambia per larghezza).

## 2. Dimensioni: `width` e `height` (o `aspect-ratio`)

Senza dimensioni il browser non sa quanto spazio riservare e la pagina salta quando l'immagine arriva (CLS).

- Ogni `<x-picture-webp>` / `<img>` ha **`width` e `height`** con le proporzioni vere dell'immagine (il CSS può poi ridimensionarla: `max-width: 100%; height: auto;` resta nel `main.css`).
- Oppure una classe CSS con **`aspect-ratio`** sull'immagine o sul contenitore (`.card__image--ratio { aspect-ratio: 4 / 3; object-fit: cover; }`, o il wrapper `.ratio .ratio-4x3` di Bootstrap): la classe contiene `ratio` nel nome, così il controllo la riconosce.
- **Da dove prendere le misure**, in ordine:
  1. il progetto ha un **artefatto `/design` di claude.ai** (link in `DESIGN.md`, nel `CLAUDE.md` del progetto o dato dall'utente): leggilo (tool Artifact, azione `read`) e usa **direttamente** le misure del componente nel design, senza ricalcolarle;
  2. i token di `DESIGN.md` (`components.<nome>.width`/`height`);
  3. la conversione della media (`registerMediaConversions()` del model: `->width(800)->height(600)`);
  4. un file statico: le sue misure reali (`getimagesize()`, o `identify` / le proprietà del file).
- Media caricate dall'admin con proporzioni libere: `aspect-ratio` + `object-fit: cover` sul contenitore, non `width`/`height` inventati.

## 3. La misura giusta per lo schermo: `:srcset`, `sizes`, `:sources`

Due casi diversi, che si possono combinare: la **stessa immagine in due larghezze** (`-sm` / `-lg`) e un'**immagine diversa per mobile** caricata nell'admin (collection `_mobile`).

### Stessa immagine, due larghezze: `<conversione>-sm` e `<conversione>-lg`

Ogni conversione che il front mostra a larghezze molto diverse fra mobile e desktop (card, cover, banner) si registra **in due misure, ognuna con la sua gemella webp**:

| Conversione | Larghezza | Uso |
|---|---|---|
| `<conversione>-sm` + `<conversione>-sm-webp` | ~2× la larghezza a schermo su mobile (es. 800px per una card a tutta larghezza su un telefono da 400px) | mobile |
| `<conversione>-lg` + `<conversione>-lg-webp` | ~1.5-2× la larghezza a schermo su desktop | tablet e desktop, e `src` di ripiego |

**Le conversioni responsive non deformano e non tagliano l'immagine**: sono la stessa immagine caricata dall'admin, solo più piccola. Si usa **`Fit::Max`** con la sola larghezza: mantiene le proporzioni originali, non ingrandisce le immagini più piccole, non taglia e non aggiunge bande.

| `Fit` | Per le conversioni responsive |
|---|---|
| **`Max`** (solo larghezza) | **sì**: proporzioni dell'originale, mai ingrandita |
| `Crop` | no: taglia |
| `Stretch` | no: deforma |
| `Fill`, `FillMax` | no: aggiunge bande di colore attorno |
| `Contain` | no: ingrandisce le immagini più piccole della misura (sgranate) |

Le larghezze (`-sm`, `-lg`) vengono dal design (artefatto `/design`, `DESIGN.md`) come al punto 2.

```php
// Model: una conversione = sm + lg, ognuna con la sua -webp; solo sulla sua collection
public function registerMediaConversions(?Media $media = null): void
{
    $sizes = [
        // nome => [collection, larghezza sm, larghezza lg]
        'card'   => ['image', 800, 960],
        'banner' => ['banner', 1080, 2880],
    ];

    foreach ($sizes as $name => [$collection, $sm, $lg]) {
        foreach (['sm' => $sm, 'lg' => $lg] as $size => $width) {
            // Fit::Max con la sola larghezza: stesse proporzioni dell'originale, mai ingrandita, niente tagli
            $this->addMediaConversion("{$name}-{$size}")
                ->fit(Fit::Max, $width)->performOnCollections($collection)
                ->nonOptimized()->nonQueued();          // hosting condiviso
            $this->addMediaConversion("{$name}-{$size}-webp")
                ->format('webp')->fit(Fit::Max, $width)->performOnCollections($collection)
                ->nonOptimized()->nonQueued();
        }
    }
}
```

```blade
<x-picture-webp :image="$product->getFirstMedia('image')" conversion="card-lg"
                :srcset="['800w' => 'card-sm', '960w' => 'card-lg']"
                sizes="(min-width: 992px) 33vw, 100vw" :alt="$product->name" width="960" height="720" />
```

- I descrittori (`800w`, `960w`) sono le larghezze delle due conversioni.
- `conversion="<conversione>-lg"`: è il `src` per i browser che ignorano `srcset`.
- `sizes` obbligatorio: dice quanto è larga l'immagine a schermo per breakpoint (qui un terzo da `lg` in su, tutta la larghezza sotto).
- Se manca anche una sola `-webp`, il componente non stampa il `<source>` webp e resta il formato originale: registrale tutte. Dopo aver aggiunto conversioni a un model con media già caricate: `php artisan media-library:regenerate --ids=...` (o per model) sul progetto, dopo averlo detto all'utente.

### Immagine diversa per mobile: la collection `<nome>_mobile`

Spesso il cliente carica una versione mobile della foto (un altro taglio, un altro design con il testo leggibile). Non è sempre presente: il front deve funzionare anche senza.

- **Admin e model**: una collection a parte `<nome>_mobile` (`singleFile()`), con il suo campo `MediaLibrary` nel `config.php` (skill `master-core-fields`) e un `help` con le misure consigliate. La sua conversione è `<conversione>-mobile` + `<conversione>-mobile-webp`, `performOnCollections('<nome>_mobile')`, con `Fit::Max` e la sola larghezza come le altre: le proporzioni sono quelle dell'immagine che il cliente ha disegnato per il mobile.
- **Controller**: prepara le sources **solo se l'immagine mobile c'è** (la Blade non decide, `blade-logic.md`):
  ```php
  $bannerMobile = $brand->getFirstMedia('banner_mobile');

  return view('pages.brands.show', [
      'brand' => $brand,
      // art direction: sotto md la versione mobile, quando l'admin l'ha caricata
      'bannerSources' => $bannerMobile ? ['(max-width: 767.98px)' => [$bannerMobile, 'banner-mobile']] : [],
  ]);
  ```
- **Vista**: passa le sources; la principale può avere anche le sue due larghezze:
  ```blade
  <x-picture-webp :image="$brand->getFirstMedia('banner')" conversion="banner-lg" :sources="$bannerSources"
                  :srcset="['1080w' => 'banner-sm', '2880w' => 'banner-lg']" sizes="100vw" priority :alt="$brand->name" />
  ```
- **Senza immagine mobile**: niente source, la principale (con `-sm` / `-lg`) vale anche per il telefono. Il componente salta comunque una voce `[null, ...]`, ma è il controller a non passarla.
- Breakpoint della media query: quelli di Bootstrap (`(max-width: 767.98px)` = sotto `md`), come `css-split.md`.
- Le proporzioni del mobile sono diverse da quelle del desktop: `width`/`height` sull'immagine valgono per la principale; se il contenitore cambia proporzioni sul telefono, usa una classe `*ratio*` con `aspect-ratio` diverso in `responsive.css`.

## 4. Iframe e video

- Ogni `<iframe>` (mappe, YouTube, Vimeo, widget) ha **`loading="lazy"`**, tranne uno che sta in cima alla pagina; più `title` (accessibilità: dice cosa contiene).
- **YouTube, Vimeo, Google Maps**: meglio una **facciata**: un'immagine di anteprima con un `<button>` «Guarda il video» / «Apri la mappa» che inserisce l'iframe solo al click. Niente centinaia di KB di script del player per chi non lo guarda, e si incastra con il consenso cookie (`cookie-consent.md`): l'iframe di terze parti parte dopo il consenso comunque.
- Iframe incollati dall'admin nell'editor (blocchi `video_embed`): non li controlli dal markup; aggiungi `loading="lazy"` lato render se il progetto li ripulisce già (`RichTextSanitizer`), altrimenti lascia com'è e segnalalo.
- `<video>`: `preload="none"` (o `metadata` se serve la durata) + `poster`; un video di sfondo è `muted` `playsinline` senza `controls` e rispetta `prefers-reduced-motion` (`html-markup.md`).

## No
- Niente immagine LCP lazy, niente `priority` su più immagini della stessa pagina.
- Niente `<img>`/`<x-picture-webp>` senza `width`/`height` né classe con `aspect-ratio`.
- Niente immagine da 2000px servita a un mobile: `<conversione>-sm`/`-lg` con `:srcset` + `sizes`.
- Niente conversione `-sm`/`-lg`/`-mobile` senza la sua gemella `-webp`.
- Niente `Fit::Crop`, `Stretch`, `Fill`, `FillMax` o `Contain` nelle conversioni responsive: solo `Fit::Max` con la larghezza.
- Niente `<source>` mobile quando l'admin non ha caricato l'immagine mobile: lo decide il controller.
- Niente `<iframe>` senza `loading="lazy"` sotto la piega; niente `<video>` che scarica tutto il file prima del play.

Verifica: `scripts/check-views.sh` (WARN: immagine senza dimensioni né classe `*ratio*`, più di un `priority` nella stessa vista, `<iframe>` senza `loading`, `:srcset` senza `sizes`). Che l'immagine con `priority` sia davvero quella LCP lo verifica l'agente con Lighthouse (voce «Largest Contentful Paint element») o con la skill `agent-skills:webperf`.
