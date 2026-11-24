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

Verifica: a mano, in review. Gli script non riconoscono due markup "quasi uguali".
