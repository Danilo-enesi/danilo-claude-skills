# Regola: sito multilingua = alternate hreflang in ogni pagina indicizzabile

Se il website ha **due o più lingue front attive**, ogni action che rende una vista indicizzabile imposta un alternate per ogni lingua in cui la pagina esiste, più `x-default`. Con una sola lingua niente alternate, nemmeno quello verso se stessa.

`Meta` riceve e stampa soltanto: `Meta::set('alternate-<lang>', $url)` → `<link rel="alternate" hreflang="<lang>" href="..." />`. Non valida né la lingua né l'URL: quali lingue, quali URL e quando, lo decide il controller.

## Come capire se il sito è multilingua

- A runtime (quello che conta): `Websites::current('enabledFrontLanguages')` ha 2+ chiavi. Il codice si basa su questo, così una lingua attivata dopo funziona senza toccare i controller.
- Leggendo il progetto: `Routes/web.php` ha un gruppo per lingua con `'locale' => '<lang>'` diversi (`routes.md`). Prova veloce: `php artisan tinker --execute="echo implode(',', array_keys(Websites::current('enabledFrontLanguages') ?: []));"`.

## Un helper per tutti i controller

Il ciclo sulle lingue sta una volta sola, in un trait dei controller del front: `private/front/Main/Controllers/Concerns/SetsAlternates.php`.

```php
<?php

namespace Front\Main\Controllers\Concerns;

use Master\Facades\Meta;
use Master\Modules\Websites\Facades\Websites;

trait SetsAlternates
{
    /**
     * $urlFor(string $lang): ?string → URL della pagina in quella lingua, null se lì la pagina non esiste.
     * $xDefault: URL per x-default; null = URL della lingua di default del website.
     */
    protected function setAlternates(callable $urlFor, ?string $xDefault = null): void
    {
        $langs = array_keys(Websites::current('enabledFrontLanguages') ?: []);
        if (count($langs) < 2) {
            return; // monolingua: niente hreflang
        }

        $urls = [];
        foreach ($langs as $lang) {
            $url = $urlFor($lang);
            if ($this->validAlternate($url)) { // mai una stringa vuota o un URL rotto
                $urls[$lang] = $url;
            }
        }
        if (count($urls) < 2) {
            return; // la pagina esiste in una lingua sola: nessuna alternativa da dichiarare
        }

        foreach ($urls as $lang => $url) {
            Meta::set("alternate-{$lang}", $url);
        }

        $xDefault ??= $urls[Websites::current('lang_front_default')] ?? null;
        if ($this->validAlternate($xDefault)) {
            Meta::set('alternate-x-default', $xDefault);
        }
    }

    private function validAlternate(mixed $url): bool
    {
        return is_string($url) && trim($url) !== '' && filter_var($url, FILTER_VALIDATE_URL) !== false;
    }
}
```

Il controller fa `use SetsAlternates;` e chiama `$this->setAlternates(...)` accanto agli altri `Meta::set` (`meta.md`).

## URL per lingua

| Pagina | `$urlFor` |
|---|---|
| statica (chi siamo, contatti) | `fn ($lang) => Front::routeLang('aboutUs', $lang)` |
| home | `fn ($lang) => Front::routeLang('home', $lang)`, con `x-default` = la root: `Front::globalRoute('root.index')` |
| lista paginata | `fn ($lang) => Front::routeLang('blog', $lang, $page > 1 ? ['page' => $page] : [])`: stessa pagina del canonical |
| dettaglio di un'entità | `fn ($lang) => $post->urlLang($lang)` |

Il dettaglio ha uno slug diverso per lingua: l'URL lo costruisce il **model**, accanto all'accessor `url` (`routes.md`), e ritorna `null` quando in quella lingua manca la traduzione o lo slug suo o di un padre.

```php
// Model Post: traduzioni caricate dal controller con ->load('translations', 'category.translations')
public function urlLang(string $lang): ?string
{
    $slug = $this->translations->firstWhere('lang', $lang)?->meta_rewurl;
    $categorySlug = $this->category?->translations->firstWhere('lang', $lang)?->meta_rewurl;

    if (blank($slug) || blank($categorySlug)) {
        return null; // senza slug l'URL sarebbe "/blog/-12/-42": in questa lingua la pagina non esiste
    }

    return Front::routeLang('post', $lang, [
        'rewurl_category' => "{$categorySlug}-{$this->category->progId}",
        'rewurl_post'     => "{$slug}-{$this->progId}",
    ]);
}
```

## x-default

- Si imposta **solo insieme agli alternate** (il trait lo fa da sé): mai su un sito monolingua, mai da solo.
- **Home**: la root `/`, perché `PagesController@index` sceglie la lingua dal browser (`controllers.md`): è esattamente il significato di x-default. Senza rotta `root.index`, la home nella lingua di default.
- **Altre pagine**: l'URL nella lingua di default del website (`Websites::current('lang_front_default')`), il default del trait.
- La pagina non esiste nella lingua di default → niente x-default (il trait lo salta): non si punta a una lingua a caso.

## Sì
- L'alternate della lingua corrente è uguale al canonical (stesso URL, stessa `page`).
- Ogni URL passato a `Meta::set('alternate-...')` è assoluto e non vuoto: passa dal trait, che scarta `null`, `''` e URL non validi.
- Le traduzioni che servono a `urlLang()` si caricano nel controller (`->load('translations')`), non una query per lingua.

## No
- Niente alternate su pagine `noindex` (ricerca, area utente, carrello, checkout) né sulle pagine di errore.
- Niente alternate verso una lingua dove la pagina non c'è (porta a un 404 o a una pagina vuota): `urlLang()` ritorna `null`.
- Niente `Meta::set('alternate-...')` scritto a mano nei controller fuori dal trait: salta il controllo sulle URL vuote.
- Niente `<link rel="alternate">` scritto nelle viste: lo stampa `Meta::render()`.
- Niente modifica in `vendor/` se il core non supporta gli alternate: si estende la classe locale (sotto).

## Core senza supporto agli alternate

Le versioni di `laravel-master-core` precedenti alla 13.8.1 ritornano `false` su `Meta::set('alternate-it', ...)` **in silenzio** e non stampano nulla. Controlla: `grep -c "alternate-" private/vendor/enesisrl/laravel-master-core/src/Foundation/Meta.php` (0 = manca). Allora sovrascrivi in `private/master/Foundation/Meta.php` (la classe registrata come `Meta`, estende quella del core), mai in `vendor/`:

```php
public function set($name, $content)
{
    // hreflang (core senza supporto): chiave alternate-<lang>, null o '' la rimuove
    if (is_string($name) && str_starts_with($name, 'alternate-')) {
        $this->properties[$name] = ($content === null || $content === '') ? null : $content;
        return true;
    }

    return parent::set($name, $content);
}

public function render(): string
{
    $html = (string) parent::render();
    foreach ($this->properties as $key => $url) {
        if ($url && str_starts_with($key, 'alternate-')) {
            $html .= '<link rel="alternate" hreflang="' . e(substr($key, 10)) . '" href="' . e($url) . '" />';
        }
    }

    return $html;
}
```

- Firma di `set($name, $content)` senza tipi, come in tutte le versioni del core; `render(): string` va bene sia col core che la dichiara sia con quello che non la dichiara.
- Se il file ha già un `set` o un `render`, aggiungi il caso lì dentro invece di crearne un secondo. L'override di `render_property` per il canonical (`meta.md`) resta com'è.
- Quando il progetto aggiorna il core a una versione col supporto, togli l'override: il core stampa già gli alternate e li stamperebbe due volte.
- Prova: `php artisan tinker --execute="Meta::set('alternate-it', 'https://esempio.it/it'); echo Meta::render();" | grep -o '<link rel=\"alternate\"[^>]*>'`.

Verifica: `scripts/check-meta.sh`: su un sito multilingua (2+ `locale` in `Routes/web.php`) ogni action indicizzabile che rende una vista chiama `setAlternates`; il core o la classe locale supportano `alternate-<lang>`. Che gli URL siano quelli giusti (slug tradotti, pagina presente in quella lingua) lo verifica l'agente rileggendo `urlLang()` e aprendo la pagina.
