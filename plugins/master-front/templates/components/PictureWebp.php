<?php

namespace Front\Main\Components;

use Illuminate\Contracts\View\View;
use Illuminate\View\Component;
use Master\Facades\Version;
use Spatie\MediaLibrary\MediaCollections\Models\Media;

/**
 * `<picture>` with a webp `<source>` when one exists, for a media-library Media (its `<conversion>-webp`) or a static
 * file under the web root (the `.webp` next to it). No image falls back to the static `$default`. Extra attributes
 * (class, width, height, loading, data-*) go on the `<img>`.
 */
class PictureWebp extends Component
{
    /** @var list<array{url: string, webp: ?string, media: ?string}> */
    public array $sources = [];

    /**
     * @param  Media|string|null  $image  a Media, or a path from the web root ('/assets/main/images/home/hero.jpg')
     * @param  string  $conversion  Media conversion for the `<img>` ('' = original file)
     * @param  array<string, string>  $sources  media query => conversion (Media) or path (static), widest first
     * @param  string  $default  static image used when `$image` is empty
     */
    public function __construct(
        public Media|string|null $image = null,
        public string $conversion = '',
        array $sources = [],
        public string $alt = '',
        public string $default = '/assets/main/images/defaults/placeholder.jpg',
    ) {
        $this->image = $image ?: $default;
        $base = $this->image instanceof Media ? $conversion : $this->image;

        foreach ([...$sources, '' => $base] as $media => $variant) {
            $this->sources[] = [...$this->variant($variant), 'media' => $media ?: null];
        }
    }

    /**
     * @return array{url: string, webp: ?string}
     */
    private function variant(string $variant): array
    {
        if ($this->image instanceof Media) {
            $webp = $variant ? "{$variant}-webp" : 'webp';

            return [
                'url' => $this->image->getUrl($variant),
                'webp' => $this->image->hasGeneratedConversion($webp) ? $this->image->getUrl($webp) : null,
            ];
        }

        $webp = preg_replace('/\.(jpe?g|png)$/i', '.webp', $variant);

        return [
            'url' => Version::get($variant),
            'webp' => $webp !== $variant && is_file(public_path($webp)) ? Version::get($webp) : null,
        ];
    }

    public function render(): View
    {
        return view('components.picture-webp');
    }
}
