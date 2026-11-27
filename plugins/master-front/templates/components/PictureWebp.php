<?php

namespace Front\Main\Components;

use Illuminate\Contracts\View\View;
use Illuminate\View\Component;
use Master\Facades\Version;
use Spatie\MediaLibrary\MediaCollections\Models\Media;

/**
 * `<picture>` with a webp `<source>` when one exists, for a media-library Media (its `<conversion>-webp`) or a static
 * file under the web root (the `.webp` next to it). No image falls back to the static `$default`. Extra attributes
 * (class, width, height, data-*) go on the `<img>`.
 */
class PictureWebp extends Component
{
    /** @var list<array{url: string, webp: ?string, media: ?string}> */
    public array $sources = [];

    /** srcset of the `<img>` and of its webp `<source>` (null when not every size has a webp) */
    public ?string $srcsetUrl = null;
    public ?string $srcsetWebp = null;

    /**
     * @param  Media|string|null  $image  a Media, or a path from the web root ('/assets/main/images/home/hero.jpg')
     * @param  string  $conversion  Media conversion for the `<img>` ('' = original file)
     * @param  array<string, string|array{0: ?Media, 1: string}>  $sources  media query => conversion (Media), path
     *         (static) or [another Media, its conversion] (art direction, e.g. the mobile image uploaded in the admin;
     *         a null Media is skipped and the main image is used), widest first
     * @param  array<string, string>  $srcset  width descriptor => conversion (Media) or path (static), e.g.
     *         ['480w' => 'card-sm', '960w' => 'card-lg']: the browser picks the size that fits `$sizes`
     * @param  ?string  $sizes  how wide the image is shown, e.g. '(min-width: 992px) 33vw, 100vw' (needed with $srcset)
     * @param  bool  $priority  LCP image (hero, cover): loaded at once with high priority instead of lazy
     * @param  string  $default  static image used when `$image` is empty
     */
    public function __construct(
        public Media|string|null $image = null,
        public string $conversion = '',
        array $sources = [],
        array $srcset = [],
        public ?string $sizes = null,
        public bool $priority = false,
        public string $alt = '',
        public string $default = '/assets/main/images/defaults/placeholder.jpg',
    ) {
        $this->image = $image ?: $default;
        $base = $this->image instanceof Media ? $conversion : $this->image;

        foreach ([...$sources, '' => $base] as $media => $variant) {
            [$source, $variant] = is_array($variant) ? $variant : [$this->image, $variant];
            if (!$source) {
                continue; // art-direction image not uploaded: the main image covers that breakpoint too
            }
            $this->sources[] = [...$this->variant($source, $variant), 'media' => $media ?: null];
        }

        if ($srcset) {
            $sizes = array_map(fn ($variant) => $this->variant($this->image, $variant), $srcset);
            $this->srcsetUrl = $this->srcsetOf($sizes, 'url');
            $this->srcsetWebp = in_array(null, array_column($sizes, 'webp'), true) ? null : $this->srcsetOf($sizes, 'webp');
        }
    }

    /**
     * @return array{url: string, webp: ?string}
     */
    private function variant(Media|string $image, string $variant): array
    {
        if ($image instanceof Media) {
            $webp = $variant ? "{$variant}-webp" : 'webp';

            return [
                'url' => $image->getUrl($variant),
                'webp' => $image->hasGeneratedConversion($webp) ? $image->getUrl($webp) : null,
            ];
        }

        $webp = preg_replace('/\.(jpe?g|png)$/i', '.webp', $variant);

        return [
            'url' => Version::get($variant),
            'webp' => $webp !== $variant && is_file(public_path($webp)) ? Version::get($webp) : null,
        ];
    }

    /**
     * @param  array<string, array{url: string, webp: ?string}>  $sizes
     */
    private function srcsetOf(array $sizes, string $key): string
    {
        return implode(', ', array_map(fn ($w, $v) => "{$v[$key]} {$w}", array_keys($sizes), $sizes));
    }

    public function render(): View
    {
        return view('components.picture-webp');
    }
}
