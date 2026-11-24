---
name: front-shared-data
description: Come portare un dato a più Blade del front Master Laravel Enesi senza query nelle viste: view composer + builder singleton per viste precise (header, footer, menu, social), Front::loadSharedContent() + Dom::config() per i dati globali del sito. Attivala quando un dato serve in più viste: «questo dato serve in header e footer», «menu del front», «social nel footer», «view composer», «dati condivisi», «contatti in tutte le pagine».
---

# Dati condivisi fra Blade

**Regola d'oro:** un dato che serve a più Blade si carica una volta per richiesta, in un posto solo.

Percorsi relativi alla radice del plugin (`../../` da questa skill).

## Passi

1. **Decidi dove** (`rules/shared-data.md`):
   - viste precise (header, footer...) → view composer
   - fatto globale del sito → `Front::loadSharedContent()`
   - una sola pagina → il controller
2. **View composer**:
   1. classe composer (una per area, es. `NavigationComposer`), con un builder iniettato che fa le query;
   2. builder registrato come `singleton` in `FrontServiceProvider::register()`;
   3. `View::composer(['partials.header', 'partials.footer'], NavigationComposer::class)` in `boot()`;
   4. se manca un dato, il composer torna una collezione vuota, non `null`.
3. **Dato globale**: in `private/master/Foundation/Front.php` implementa `loadSharedContent()` con `Dom::config('chiave', $valore)`. Nella Blade: `Dom::config('chiave')`. Solo dati pochi e leggeri.

## No
- Niente query nella Blade, niente `View::composer('*', ...)`.
- Niente stesso array ricalcolato in ogni controller.
