# Regola: meta tag, in ogni action che rende una vista

`{!! Meta::render() !!}` in head stampa tutto: title, description, canonical, robots, OpenGraph, Twitter. I valori li imposta **il controller**, prima di `view()`.

## Obbligatori in ogni action che fa `return view(...)`

```php
Meta::set('title', $post->meta_title ?: $post->title);
Meta::set('description', $post->meta_description ?: $post->summary);
Meta::set('canonical', $post->url); // URL con gli slug giusti (routes.md)
```

| Chiave | Valore | Perché va impostata |
|---|---|---|
| `title` | dal CMS con fallback (`meta_title ?: titolo`); pagine statiche: `__('front::controllers.<pagina>_meta_title')` | senza, la pagina non ha title |
| `description` | dal CMS con fallback (`meta_description ?: riassunto`); statiche: `__('front::controllers.<pagina>_meta_desc')` | senza, niente description |
| `canonical` | URL pulito della rotta: `Front::route('<nome>', [...])` | il fallback del core è l'URL richiesto: dal 13.8.1 senza query string (tiene solo `page` > 1), nei core più vecchi `request()->fullUrl()` con `?utm_...`, filtri, ordinamenti. In entrambi i casi non corregge slug o percorsi sbagliati |

Sito multilingua: in più gli alternate hreflang e x-default, con `$this->setAlternates(...)` (`alternates.md`).

## og:tags

| Chiave | Quando impostarla | Fallback del core |
|---|---|---|
| `og:image` | sempre se la pagina ha un'immagine sua (cover, prima foto): URL assoluto | logo del website |
| `og:type` | dettagli: `article` (post), `product` (prodotto) | `website` |
| `og:title`, `og:description` | solo se devono essere diversi da title/description | title / description |
| `og:url` | mai: si allinea da solo | URL della richiesta |
| `og:locale`, `og:site_name`, `twitter:*` | mai | dal website |

## Sì
- Liste paginate: canonical con la sola pagina (> 1), senza filtri né ordinamenti. La **pagina 1 è sempre la lista base**: canonical senza `page`, e una richiesta con `?page=1` si rimanda alla lista base (vedi sotto).
- Pagine da non indicizzare (ricerca, area utente, carrello, checkout): `Meta::set('robots', 'noindex, nofollow')`; title e description restano obbligatori, il canonical si può omettere.
- Testi statici dei meta nel file di traduzione `front::controllers`, non scritti nel controller.

## Pagina 1 = lista base

```php
public function index(Request $request) {
    $page = (int) $request->query('page', 1);

    // ?page=1 (o meno) duplica la lista base: si rimanda lì, conservando gli altri parametri
    if ($request->has('page') && $page <= 1) {
        return Response::redirectTo(Front::route('blog', $request->except('page')), 301);
    }

    Meta::set('canonical', Front::route('blog', $page > 1 ? ['page' => $page] : []));
    // ...
}
```

## Bug del core: canonical stampato come `<meta>`

Nelle versioni di `laravel-master-core` precedenti alla 2.4.2 la classe `Meta` stampa il canonical come `<meta name="canonical" rel="...">`, che i motori ignorano: deve essere `<link rel="canonical" href="...">`.

1. **Controlla**: `scripts/check-meta.sh` (statico: riconosce `<link rel="canonical"` scritto per esteso o costruito dal nome, con qualsiasi spaziatura). Il controllo statico può sbagliare su uno stile nuovo: dove c'è PHP, prima di correggere conferma con la prova vera:
   ```bash
   php artisan tinker --execute="Meta::set('canonical', 'https://esempio.it/a'); echo Meta::render();" | grep -i canonical
   ```
   Deve uscire `<link rel="canonical" ...>`.
2. **Correggi in locale**, mai in `vendor/`: in `private/master/Foundation/Meta.php` (la classe che il core registra come `Meta`, estende quella del core) sovrascrivi `render_property`. **Stessa firma del core installato**:
   ```php
   // core v2.x: protected function render_property(?string $name): ?string
   // core v1.x: protected function render_property($name)
   protected function render_property(?string $name): ?string
   {
       // Il core stampa <meta name="canonical">, che i motori ignorano
       if (in_array($name, ['canonical', 'prev', 'next'], true)) {
           $content = $this->get($name);
           return $content ? '<link rel="' . e($name) . '" href="' . e($content) . '" />' : null;
       }

       return parent::render_property($name);
   }
   ```
3. Se il file ha già un `render_property`, aggiungi il caso lì dentro invece di crearne un secondo.

## Bug del core: canonical di fallback con tutta la query string

Nelle versioni di `laravel-master-core` precedenti alla 13.8.1 il canonical e l'`og:url` non impostati valgono `request()->fullUrl()`: `?utm_source=...`, filtri e ordinamenti finiscono nel canonical. Dalla 13.8.1 il core usa l'URL senza query string (tiene solo `page` > 1).

1. **Controlla**: `scripts/check-meta.sh`, o `grep -n "fullUrl" private/vendor/enesisrl/laravel-master-core/src/Foundation/Meta.php`. Nessun risultato → il core è già corretto: **non fare nulla**.
2. **Correggi in locale**, mai in `vendor/`: in `private/master/Foundation/Meta.php` sovrascrivi `get`, con lo stesso fallback del core 13.8.1:
   ```php
   public function get($name)
   {
       // Core < 13.8.1: il fallback è request()->fullUrl(), con utm, filtri e ordinamenti
       if (in_array($name, ['canonical', 'og:url'], true) && empty($this->properties[$name])) {
           $page = filter_var(request()->query('page'), FILTER_VALIDATE_INT, ['options' => ['min_range' => 2]]);

           return $page ? url()->current() . '?page=' . $page : url()->current();
       }

       return parent::get($name);
   }
   ```
   `get($name)` senza tipo va bene con tutte le firme del core (`get($name)` e `get(?string $name)`).
3. Se il file ha già un `get`, aggiungi il caso lì dentro invece di crearne un secondo.
4. Quando il progetto aggiorna il core alla 13.8.1 o successiva, togli l'override: è identico a quello del core.

L'override corregge solo il fallback: il canonical resta da impostare in ogni action (sopra).

## No
- Niente `<title>`/`<meta>`/`<link rel="canonical">` a mano nelle viste.
- Niente canonical lasciato al fallback, né costruito con `url()->current()` / `request()->fullUrl()`.
- Niente troncamenti a mano: `Meta` taglia già a 160 caratteri.
- Niente `og:url` impostato a mano e diverso dal canonical.
- Una chiave nuova (es. `theme-color`) non si stampa nella vista: si estende la mappa in `private/master/Foundation/Meta.php`.

Verifica: `scripts/check-meta.sh`: ogni metodo con `return view(` ha title, description e canonical (`noindex` esenta dal canonical); il canonical si stampa come `<link>` (bug del core corretto in `private/master/Foundation/Meta.php`).
