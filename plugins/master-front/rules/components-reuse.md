# Regola: ciò che si usa due volte è un componente

Un pezzo di markup che compare in **due o più viste** (card, bottone, titolo di sezione, immagine `<picture>`...) vive **una volta sola** in `components/` e le viste lo richiamano con `<x-...>`.

## Raggruppati per concetto

`components/<concetto>/<nome>.blade.php`, richiamati con `<x-concetto.nome />`. Il concetto è l'entità o l'area del sito, non il tipo di markup.

| Componente | Dove |
|---|---|
| card di un post, sidebar del blog | `components/blog/post-card.blade.php`, `components/blog/sidebar.blade.php` |
| carrello, riepilogo ordine | `components/ecommerce/cart.blade.php`, `components/ecommerce/order-resume.blade.php` |
| blocchi di contenuto | `components/blocks/gallery-block.blade.php` |
| generico, senza concetto (immagine, bottone, select) | radice: `components/picture-webp.blade.php` |

La classe, se c'è, segue la stessa cartella: `private/front/Main/Components/Blog/PostCard.php` (namespace `Front\Main\Components\Blog`).

## Class based component: registrazione

Ogni componente con classe si registra nel **`FrontServiceProvider`** (`private/app/Providers/FrontServiceProvider.php`), nel metodo `boot()`; se il progetto non ha un `FrontServiceProvider`, nell'**`AppServiceProvider`**.

```php
use Illuminate\Support\Facades\Blade;
use Front\Main\Components\Breadcrumb;
use Front\Main\Components\Blog\PostCard;

Blade::component('breadcrumb', Breadcrumb::class);
Blade::component('blog.post-card', PostCard::class);
```

Il nome registrato è quello del tag (`<x-blog.post-card>`) e la classe fa `render()` della vista con lo stesso percorso (`view('components.blog.post-card')`).

## Sì
- Seconda volta che serve lo stesso pezzo → spostalo in `components/<concetto>/<nome>.blade.php` e sostituisci **entrambe** le copie con `<x-concetto.nome ... />`.
- Le differenze fra un uso e l'altro diventano props (`@props(['title', 'size' => 'md'])`) o slot, non una seconda copia.
- Componente con poca logica → solo Blade anonima con `@props`.
- Componente con molta logica (prepara dati, calcola url o prezzi, sceglie varianti) → **class based component**: la classe in `private/front/Main/Components/` fa i conti, la Blade mostra soltanto.
- Prima di scrivere una card nuova cerca nella cartella del suo concetto in `components/`: riusa o estendi quella.
- Immagini: `<x-picture-webp>`, mai un `<picture>` scritto a mano. Media della media library: `<x-picture-webp :image="$media" conversion="cover" :alt="$titolo" />`; file statico: `<x-picture-webp image="/assets/main/images/home/hero.jpg" :alt="__('front::home.hero_alt')" />`. Il webp lo trova da solo (conversione `<conversion>-webp` o `.webp` accanto al file); `:sources` (media query → conversione o percorso) per l'art direction; gli altri attributi (`class`, `loading`, `width`...) vanno sull'`<img>`.

## No
- Niente cartelle per tipo (`components/cards/`, `components/buttons/`) né tutto piatto nella radice di `components/`: si raggruppa per concetto.
- Niente due card che sono la stessa card con markup copiato in viste diverse (es. una card del post dentro `pages/blog/index` e un'altra uguale in `pages/home/index`: è `components/blog/post-card`).
- Niente `@include` di una pagina dentro un'altra per riusarne un pezzo: il pezzo va in `components/`.
- Niente classe di componente non registrata, né registrata in un provider diverso da `FrontServiceProvider` (o `AppServiceProvider` se il primo non c'è).
- Niente logica pesante (query, cicli che trasformano dati) nella Blade di un componente: va nella sua classe.
- Niente varianti `card-home`, `card-blog`, `card-related` quando cambiano solo testo o classi: una card con props.

## Stessa struttura, dati diversi: è lo stesso componente

Due blocchi sono lo stesso componente quando hanno **lo stesso scheletro**: stessi tag annidati e stesse classi CSS (quindi stessi stili). Non conta cosa mostrano: immagine, link, testo, breadcrumb che cambiano da una vista all'altra sono **props**, non un motivo per tenere due copie. Es. il titolo di pagina con sfondo, `<h1>` e breadcrumb scritto in `pages/brands/show` e di nuovo in `pages/models/show`, con immagini e link diversi → un solo `components/page-title.blade.php` con `@props(['title', 'image', 'breadcrumb' => []])`.

Come accorgersene, **prima** di scrivere un blocco in una vista:
1. Prendi la classe radice del blocco (`page-title`, `hero`, `product-card`) e cercala in tutte le viste: `grep -rn 'class="[^"]*page-title' private/front/Main/Views`.
2. La trovi in un'altra vista fuori da `components/` → confronta lo scheletro ignorando i valori (testi, `{{ ... }}`, `src`, `href`). Uguale, o diverso solo in classi modificatrici (`--dark`, `--small`) → è lo stesso componente: estrailo e sostituisci entrambe le copie.
3. Quello che cambia diventa:
   - un dato → una prop (`:image`, `:title`, `:breadcrumb`) preparata dal controller (`blade-logic.md`);
   - una variante grafica → una prop che sceglie la classe modificatrice (`variant="dark"` → `@class(['page-title', 'page-title--dark' => $variant === 'dark'])`);
   - un pezzo di markup in più → uno slot.

### La verifica la fa l'agente, leggendo le viste

Nessuno script dice in modo affidabile se due pezzi sono lo stesso componente, né se vale la pena farne uno: lo decide l'agente che scrive la vista, leggendo e confrontando il markup. I passi 1-3 li fa **ogni volta** che scrivi o modifichi una vista, anche se lo script non segnala nulla: copie con classi rinominate o riordinate, markup simile con nomi di classe diversi, un pezzo che oggi è in una vista sola ma è chiaramente la stessa cosa di un componente già esistente sfuggono allo script.

Vale la pena farne un componente quando:
- ha un ruolo riconoscibile nel sito (titolo di pagina, card, banner, breadcrumb), non è solo un `<div>` con due classi;
- una modifica grafica fatta in una copia andrebbe fatta anche nell'altra;
- le differenze stanno in props o slot senza riempire il componente di `@if` per ogni uso.

Non vale la pena quando la somiglianza è casuale (due righe di griglia, un wrapper) o quando per unire le copie servirebbe un componente pieno di rami, uno per vista: lì due pezzi separati si leggono meglio. Nel dubbio, l'agente lo dichiara nel riepilogo del lavoro ("`X` in `pages/a` somiglia a `components/y`: non unito perché ...") invece di decidere in silenzio.

`check-views.sh` aiuta solo a trovare i casi evidenti: segnala (WARN) le viste fuori da `components/` che hanno in comune una sequenza di almeno 3 attributi `class` (le classi di utilità di Bootstrap non contano). Un WARN va valutato con i criteri sopra; nessun WARN non vuol dire nessuna copia.
