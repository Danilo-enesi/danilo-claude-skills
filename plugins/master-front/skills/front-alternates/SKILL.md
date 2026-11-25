---
name: front-alternates
description: Alternate hreflang del front Master Laravel Enesi nei siti multilingua - Meta::set('alternate-<lang>', $url) per ogni lingua in cui la pagina esiste più alternate-x-default, tramite il trait SetsAlternates che salta i siti monolingua e scarta le URL vuote; urlLang() nel model per i dettagli con slug tradotti; override in private/master/Foundation/Meta.php se il core non supporta gli alternate. Attivala quando crei o modifichi un'action che fa `return view(...)` in un sito con più lingue front, o quando si parla di «hreflang», «alternate», «x-default», «versioni in altre lingue», «SEO multilingua», «aggiungo una lingua al sito». Non serve sui siti con una sola lingua.
---

# Alternate hreflang

**Regola d'oro:** sito multilingua → ogni pagina indicizzabile dichiara le sue versioni nelle altre lingue, solo quelle che esistono davvero, mai con un URL vuoto. Sito monolingua → niente.

Percorsi relativi alla radice del plugin (`../../` da questa skill). Tutto il dettaglio e il codice: `rules/alternates.md`.

## Passi

1. **Il sito è multilingua?** `Routes/web.php` con 2+ gruppi `'locale'`, o `Websites::current('enabledFrontLanguages')` con 2+ lingue. Una sola lingua → fermati: niente alternate né x-default.
2. **Il core supporta gli alternate?** `grep -c "alternate-" private/vendor/enesisrl/laravel-master-core/src/Foundation/Meta.php`. 0 (e nemmeno `private/master/Foundation/Meta.php` li gestisce) → aggiungi l'override di `set` e `render` in `private/master/Foundation/Meta.php` (`rules/alternates.md`), mai in `vendor/`.
3. **Il trait** `private/front/Main/Controllers/Concerns/SetsAlternates.php` esiste? Se no, crealo dal codice della regola. Fa lui: salto sui siti monolingua, scarto di `null`/`''`/URL non validi, niente alternate se resta una lingua sola, x-default.
4. **In ogni action indicizzabile** che rende una vista: `use SetsAlternates;` nel controller e `$this->setAlternates(fn ($lang) => ..., $xDefault)` accanto a title/description/canonical (skill `front-meta`):
   - statica: `Front::routeLang('<rotta>', $lang)`;
   - home: idem, con `x-default` = `Front::globalRoute('root.index')` (la root che sceglie la lingua dal browser);
   - lista paginata: stessa `page` del canonical;
   - dettaglio: `$model->urlLang($lang)`, che ritorna `null` se in quella lingua manca la traduzione o lo slug (suo o dei padri). Se il model non ce l'ha, aggiungilo accanto all'accessor `url`, e carica `translations` nel controller.
5. **x-default**: lo imposta il trait con l'URL della lingua di default del website; passalo esplicito solo per la home. Pagina assente nella lingua di default → niente x-default.
6. **Salta** le pagine `noindex` (ricerca, area utente, carrello, checkout) e quelle di errore.
7. **Verifica**: `bash scripts/check-meta.sh <root>`, poi apri una pagina e controlla i `<link rel="alternate">` nel sorgente: una riga per lingua, quella corrente uguale al canonical, nessun `href=""` né slug vuoto (`/-42`).

## No
- Niente `Meta::set('alternate-...')` a mano fuori dal trait: salta il controllo sulle URL vuote.
- Niente alternate verso una lingua in cui la pagina non c'è.
- Niente `<link rel="alternate">` nelle viste.
- Niente modifiche in `vendor/`.
