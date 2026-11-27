# Regola: niente CSS/JS inline nelle Blade

## Sì
- CSS e JS in file sotto `assets/main/` (vedi `assets-structure`).
- CSS/JS di una sola pagina o componente: `@push('styles')` / `@push('scripts')` con un `<link>`/`<script src>` versionato.
- Componente presente più volte: `@pushOnce('scripts', 'chiave')`.
- Pagina con molte librerie o molto JS suo: `pages/<entità>/scripts.blade.php` con soli `@push` di `<script src>`/`<link>` (`scripts-loading.md`).
- Dati per il JS: attributi `data-*` sul markup, o `window.front`.

## No
- Niente `<style>` o `<script>` nelle Blade. Eccezioni: `partials/base/` (`window.front`, gtag, callbacks), `<script type="application/ld+json">` e `mail/` (i client email leggono solo CSS inline).
- Niente `onclick=""` e simili.
- `style=""` solo per un valore dinamico (es. `background-image` da DB): è un WARN, non un'abitudine.

Verifica: `scripts/check-views.sh`
