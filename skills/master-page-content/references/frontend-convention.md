# Convenzione frontend generica per i blocchi

Il frontend di ogni progetto è quasi sempre **il pezzo più specifico** del sistema Contents — cambia design, libreria di gallery/lightbox, breakpoint, framework CSS. Questo file **non** documenta l'implementazione di un progetto specifico (per quello, guarda il frontend reale del progetto in cui stai lavorando): dà una **baseline minima e coerente** da cui partire in un progetto nuovo, o da usare come riferimento quando il frontend esistente non copre ancora un tipo di blocco.

> Presuppone `references/package-internals.md` Capa 5 (`getBlockData`/`getContentMedia`) e il catalogo tipi in `references/conventional-blocks.md`.

## La convenzione

1. **Niente sidebar/aside.** Ogni blocco occupa tutta la larghezza disponibile del suo contenitore.
2. **Due sole larghezze possibili:**
   - **full-width del contenitore padre** (default per quasi tutti i tipi) — il blocco rispetta il padding/max-width della pagina.
   - **full-bleed, tutta la larghezza del browser** — solo per `image_full` sempre, e per `text`/`video_embed` quando `data.layout === 'full-width'` (opzione admin, vedi `conventional-blocks.md`).
3. **Una classe CSS dedicata per blocco, in inglese**, sul suo elemento radice: `block-title`, `block-text`, `block-article`, `block-gallery`, `block-attachments`, `block-video`, `block-image-full`. Nessuna classe generica condivisa oltre a questa (a differenza di progetti esistenti che usano `.typo-block.block-xxx` per allinearsi a un design system preesistente — qui non ne assumiamo uno).
4. **Ogni componente decide da solo se è full-bleed**, leggendo i propri dati (`layout`) — non è una decisione del renderer globale.
5. Dove l'implementazione dipende necessariamente da una scelta di progetto (libreria di gallery/lightbox), il blocco è marcato esplicitamente **PLACEHOLDER**: markup semantico minimo, funzionante senza JS, ma da sostituire prima di andare in produzione.

### Utility full-bleed (CSS, senza JS)

Tecnica standard per uscire da un contenitore centrato senza conoscere la sua larghezza:

```css
.block-full-bleed {
    width: 100vw;
    margin-left: calc(50% - 50vw);
    margin-right: calc(50% - 50vw);
}
```

---

## Renderer

Il renderer resta intenzionalmente **stupido**: legge `$model->blocks` (Capa 5) e delega ogni blocco al componente del suo `type`. Nessuna logica di grouping/aside/header — quella è complessità di design specifica del progetto, non della baseline.

```php
// Front/Main/Components/Blocks/BlockRenderer.php
namespace Front\Main\Components\Blocks;

use Illuminate\Contracts\View\View;
use Illuminate\View\Component;

class BlockRenderer extends Component
{
    public function __construct(public $model) {}

    public function render(): View
    {
        return view('components.blocks.block-renderer');
    }
}
```

```blade
{{-- Views/components/blocks/block-renderer.blade.php --}}
@foreach($model->blocks as $block)
    @switch($block->type)
        @case('title') <x-blocks.title :block="$block" /> @break
        @case('text') <x-blocks.text :block="$block" /> @break
        @case('article') <x-blocks.article :block="$block" /> @break
        @case('gallery') <x-blocks.gallery :block="$block" /> @break
        @case('attachments') <x-blocks.attachments :block="$block" /> @break
        @case('video_embed') <x-blocks.video :block="$block" /> @break
        @case('image_full') <x-blocks.image-full :block="$block" /> @break
    @endswitch
@endforeach
```

> **Nota sul grouping di `attachments` consecutivi**: alcuni progetti uniscono blocchi `attachments` consecutivi senza `body` in un unico elenco visivo ("Allegati"). È un miglioramento legittimo ma NON fa parte della baseline — richiede logica nel renderer (guardare il blocco successivo/precedente) che qui teniamo fuori apposta. Aggiungilo solo se il progetto lo richiede esplicitamente, dentro `BlockRenderer`, non dentro il componente del singolo blocco.

---

## `title`

```php
// TitleBlock.php
class TitleBlock extends Component
{
    public function __construct(public $block) {}
    public function render(): View { return view('components.blocks.title'); }
}
```

```blade
{{-- title.blade.php --}}
@if($text = $block->getBlockData('text'))
    <p class="block-title">{{ $text }}</p>
@endif
```

---

## `text`

Due varianti guidate da `data.style`: `standard` e `citazione`. `layout === 'full-width'` si applica solo alla variante `citazione`.

```php
class TextBlock extends Component
{
    public bool $isQuote;
    public bool $fullBleed;

    public function __construct(public $block)
    {
        $this->isQuote = $block->getBlockData('style') === 'citazione';
        $this->fullBleed = $this->isQuote && $block->getBlockData('layout') === 'full-width';
    }

    public function render(): View { return view('components.blocks.text'); }
}
```

```blade
{{-- text.blade.php --}}
@if($isQuote)
    <blockquote class="block-text block-text--quote {{ $fullBleed ? 'block-full-bleed' : '' }}"
        style="{{ $block->getBlockData('color') ? 'color:'.$block->getBlockData('color').';' : '' }}{{ $block->getBlockData('bg_color') ? 'background-color:'.$block->getBlockData('bg_color').';' : '' }}">
        {!! $block->getBlockData('text') !!}
    </blockquote>
@else
    <div class="block-text">{!! $block->getBlockData('text') !!}</div>
@endif
```

`data.text` è HTML già validato dall'editor admin (summernote) — va sempre stampato con `{!! !!}`, mai escapato.

---

## `article` (testo + immagine)

`data.option` è il layout (`left-pic-right-text`, `right-pic-left-text`, `top-pic-bottom-text`, `bottom-pic-top-text`) — qui usato come modificatore BEM, non come classe a parte.

```php
class ArticleBlock extends Component
{
    public $image;

    public function __construct(public $block)
    {
        $this->image = $block->getContentMedia('Article');
    }

    public function render(): View { return view('components.blocks.article'); }
}
```

```blade
{{-- article.blade.php --}}
<div class="block-article block-article--{{ $block->getBlockData('option') ?? 'left-pic-right-text' }}">
    @if($image)
        <img class="block-article__image" src="{{ $image->getUrl() }}" alt="" loading="lazy" />
    @endif
    <div class="block-article__text">{!! $block->getBlockData('text') !!}</div>
</div>
```

L'ordine visivo (immagine prima/dopo, sopra/sotto) è responsabilità del CSS che leggi sul modificatore `--left-pic-right-text` ecc. — non del markup, che resta identico per tutte le varianti.

---

## `gallery` — ⚠️ PLACEHOLDER, non pronto per produzione

**Perché è un placeholder e non un'implementazione**: ogni progetto reale finora ha scelto una libreria diversa per carousel/lightbox (slider custom, lightGallery, PhotoSwipe, GLightbox...), con markup e attributi `data-*` specifici della libreria. Non esiste un default "giusto" — decidere qui una libreria significherebe imporla a tutti i progetti futuri.

Markup minimo, semanticamente corretto, **funzionante senza JS** (elenco di link alle immagini a piena risoluzione — un browser li apre comunque):

```php
class GalleryBlock extends Component
{
    public $images;

    public function __construct(public $block)
    {
        $this->images = $block->getContentMedia('Gallery') ?? collect();
    }

    public function render(): View { return view('components.blocks.gallery'); }
}
```

```blade
{{-- gallery.blade.php — PLACEHOLDER: sostituisci con la libreria scelta dal progetto --}}
@if($images->isNotEmpty())
    <ul class="block-gallery">
        @foreach($images as $image)
            <li class="block-gallery__item">
                <a href="{{ $image->getUrl() }}">
                    <img src="{{ $image->getUrl('gallery-thumb') ?: $image->getUrl() }}" alt="" loading="lazy" />
                </a>
            </li>
        @endforeach
    </ul>
@endif
```

**Prima di andare in produzione**: scegli una libreria, sostituisci il markup di `gallery.blade.php` con quello richiesto dalla libreria (attributi `data-*`, wrapper aggiuntivi), e registra gli asset JS/CSS nel bundle del progetto. Non lasciare questo placeholder in un sito live — funziona, ma l'esperienza (niente carousel/lightbox) non è quella richiesta da un blocco "galleria".

---

## `attachments`

`data.body` è HTML opzionale (intro/descrizione); se presente il blocco è "standalone", altrimenti è pensato per essere raggruppato con altri (vedi nota sul grouping più sopra — qui il caso semplice, senza grouping).

```php
class AttachmentsBlock extends Component
{
    public $files;

    public function __construct(public $block)
    {
        $this->files = $block->getContentMedia('Attachment') ?? collect();
    }

    public function render(): View { return view('components.blocks.attachments'); }
}
```

```blade
{{-- attachments.blade.php --}}
<div class="block-attachments">
    @if($body = $block->getBlockData('body'))
        <div class="block-attachments__body">{!! $body !!}</div>
    @endif
    @if($files->isNotEmpty())
        <ul class="block-attachments__list">
            @foreach($files as $file)
                <li><a href="{{ $file->getUrl() }}" download>{{ $block->getBlockData('text') ?: $file->name }}</a></li>
            @endforeach
        </ul>
    @endif
</div>
```

---

## `video_embed`

`data.text` è l'HTML dell'embed (iframe YouTube/Vimeo/Instagram — generato dall'editor admin, non da costruire lato front); `data.caption` è opzionale; `data.layout === 'full-width'` è full-bleed.

```php
class VideoBlock extends Component
{
    public bool $fullBleed;

    public function __construct(public $block)
    {
        $this->fullBleed = $block->getBlockData('layout') === 'full-width';
    }

    public function render(): View { return view('components.blocks.video'); }
}
```

```blade
{{-- video.blade.php --}}
<div class="block-video {{ $fullBleed ? 'block-full-bleed' : '' }}">
    <div class="block-video__embed">{!! $block->getBlockData('text') !!}</div>
    @if($caption = $block->getBlockData('caption'))
        <p class="block-video__caption">{{ $caption }}</p>
    @endif
</div>
```

Se l'embed non è già responsive (dipende da cosa incolla l'admin), il CSS di `.block-video__embed` deve forzare `iframe { width:100%; aspect-ratio:16/9; }` — non è controllabile dal markup Blade.

---

## `image_full` (custom, sempre full-bleed)

```php
class ImageFullBlock extends Component
{
    public $image;
    public bool $parallax;

    public function __construct(public $block)
    {
        $this->image = $block->getContentMedia('ImageFull');
        $this->parallax = $block->getBlockData('option') === 'si';
    }

    public function render(): View { return view('components.blocks.image-full'); }
}
```

```blade
{{-- image-full.blade.php --}}
<div class="block-image-full block-full-bleed {{ $parallax ? 'block-image-full--parallax' : '' }}"
     @if($image) style="background-image:url('{{ $image->getUrl() }}');" @endif>
    @if($text = $block->getBlockData('text'))
        <div class="block-image-full__overlay">{!! $text !!}</div>
    @endif
</div>
```

Il parallax (se `data.option === 'si'`) è un effetto JS/CSS specifico del progetto — qui solo il modificatore di classe è previsto, l'implementazione dell'effetto no.

---

## Errori da evitare

- ❌ Costruire il layout (sidebar, colonne, griglia editoriale) dentro un componente di blocco — quella è composizione di pagina, non del blocco singolo.
- ❌ Copiare il markup `gallery` in produzione senza sostituire la libreria — è marcato PLACEHOLDER apposta.
- ❌ Riusare classi CSS generiche non dedicate (`.card`, `.section`) come classe radice di un blocco — ogni tipo ha la sua (`block-<tipo>`), anche se visivamente simile a un altro.
- ❌ Mettere la logica di full-bleed nel renderer globale invece che nel componente — un domani un nuovo tipo full-bleed condizionale (come `text`/`video_embed`) richiederebbe di toccare il renderer invece del proprio componente.
