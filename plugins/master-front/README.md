# master-front

Plugin che imposta e descrive il **front** dei progetti Master Laravel Enesi (tema **Main**): scaffolding di Views e
assets, e un manuale d'uso per l'AI fatto di skill piccole, regole satellite e controlli automatici.

```
/plugin install master-front --marketplace Danilo-enesi/danilo-claude-skills
```

## Come è fatto

```
plugins/master-front/
├── commands/scaffold.md   /master-front:scaffold [root]: crea Views + assets dai template, non sovrascrive mai
├── commands/rescaffold.md /master-front:rescaffold [root]: riscrive i file dei template e toglie Views/base/, con backup in .scaffold-backup/
├── skills/                skill atomiche (una per lavoro), entry point: front-manual
├── rules/                 regole satellite: una regola per file, l'id è il nome del file
├── templates/             layout, head, scripts, header, footer, home, componente picture-web-p (+ classe), main.css, responsive.css, main.js
└── scripts/               scaffold.sh + check-*.sh (OK / WARN / FAIL con il rimando alla regola)
```

- Le **skill** dicono *cosa fare*, in passi brevi, e rimandano alle regole.
- Le **regole** dicono *cosa è giusto e cosa no* (Sì / No) e quale script le verifica.
- Gli **script** controllano le regole al posto tuo: ogni riga `FAIL [id]` punta a `rules/<id>.md`.

## Skill

| Skill | Quando |
|---|---|
| `front-manual` | punto di ingresso: quale skill per quale lavoro, flusso, regole sempre valide |
| `front-views` | scrivere pagine, partial, componenti |
| `front-layout` | `layouts/main.blade.php` |
| `front-head` | `partials/base/head.blade.php`: meta, font, CSS, gtag |
| `front-scripts` | `partials/base/scripts.blade.php`: window.front, librerie, JS, callbacks Beers |
| `front-assets` | dove va un file in `assets/` |
| `front-cookie-consent` | risorse di terze parti e cookie banner EPP |
| `front-meta` | title, description, og:image |
| `front-shared-data` | dati condivisi fra più viste |
| `front-mail` | email: trova se il design vive nell'admin o nel front e lavora solo lì |

## Controlli

```bash
bash plugins/master-front/scripts/check-all.sh <root-progetto>   # tutti
bash plugins/master-front/scripts/check-views.sh <root-progetto> # uno solo (views, layout, head, scripts, assets)
```

Senza argomento usano la root git della cartella corrente. Exit code 1 se c'è almeno un `FAIL`.

## Convenzioni

- `Views/layouts/` solo layout; `Views/partials/base/` head e scripts; `components/<concetto>/`; `pages/<entità>/`; `mail/` per template e blocchi delle email.
- Ciò che si usa due volte è un componente (`rules/components-reuse.md`).
- `assets/main/` = tema Main; Beers in `assets/common/beers/`; email utente in `assets/mail/`.
- CSS globale `main.css`, media query solo in `responsive.css`, in produzione `base.min.css` / `base.min.js`.
