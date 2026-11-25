<?php

namespace Front\Main\Components;

use Illuminate\View\Component;
use Master\Facades\Version;
use Master\Modules\Websites\Facades\Websites;

/**
 * `<link>` to the CSS with the fixes of the current language (`<directory>/<iso_code2>.css`, e.g. tl.css), loaded in the
 * head after the site CSS in both environments (outside base.min.css). Renders nothing when the language has no file.
 * Extra attributes (media, id, data-*) go on the `<link>`.
 */
class LangCss extends Component
{
    public ?string $href = null;

    /**
     * @param  bool  $versioned  through Version::get(), so browsers drop the cached copy when the file changes
     * @param  string  $directory  folder of the language files, from the web root
     */
    public function __construct(bool $versioned = true, string $directory = 'assets/main/css/lang')
    {
        $path = '/'.trim($directory, '/').'/'.Websites::currentLanguage('iso_code2').'.css';

        if (is_file(public_path($path))) {
            $this->href = $versioned ? Version::get($path) : asset($path);
        }
    }

    public function shouldRender(): bool
    {
        return $this->href !== null;
    }

    public function render(): string
    {
        return '<link href="{{ $href }}" {{ $attributes->merge([\'rel\' => \'stylesheet\']) }}>';
    }
}
