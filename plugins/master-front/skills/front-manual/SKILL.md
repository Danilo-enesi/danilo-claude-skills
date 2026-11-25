---
name: front-manual
description: Manuale d'uso del FRONT nei progetti Master Laravel Enesi (tema Main, `private/front/Main/` + `assets/`). Punto di ingresso: dice quale skill del plugin master-front caricare per ogni lavoro sul front e come verificare con gli script. Attivala PRIMA di qualunque lavoro sul front pubblico: «crea/modifica una pagina del front», «nuova vista Blade», «header/footer», «dove metto questo CSS/JS/immagine», «layout del front», «scaffolding del front», «controlla il front».
---

# Manuale del front (Master Laravel Enesi)

**Regola d'oro:** ogni cosa del front ha un posto fisso e una regola. Prima trovi il posto, poi scrivi, poi lanci gli script.

I percorsi `rules/`, `scripts/`, `templates/` sono relativi alla radice del plugin (`../../` da questa skill).

## 1. Quale skill per quale lavoro

| Lavoro | Skill |
|---|---|
| progetto nuovo o front da impostare | comando `/master-front:scaffold` |
| vedere cosa cambierebbe lo scaffold, senza toccare nulla | comando `/master-front:analysis` |
| il sito ha sitemap, structured data, llms.txt, robots.txt, SEO, Core Web Vitals? (solo verifica) | comando `/master-front:site-checklist` |
| scrivere una vista (pagina, partial, componente) | `front-views` |
| CSS e markup con lingue RTL, CJK o a testo lungo (arabo, cinese, tedesco, russo...) | `front-lang-css` |
| semantica e accessibilità di qualsiasi markup (tag, titoli, form, alt, link esterni) | `front-html` |
| toccare `layouts/main.blade.php` | `front-layout` |
| scrivere CSS o markup a partire dal design (`DESIGN.md`) | `front-design` |
| aggiungere CSS, font, librerie, icone in `<head>` | `front-head` |
| installare una libreria/plugin JS o CSS (prima la CDN di Enesi) | `front-cdn` |
| aggiungere JS o librerie JS | `front-scripts` |
| salvare un file in `assets/` | `front-assets` |
| script, iframe o font di terze parti | `front-cookie-consent` |
| title, description, canonical, og:tags (ogni action che rende una vista) | `front-meta` |
| alternate hreflang e x-default (sito con 2+ lingue front) | `front-alternates` |
| pagina di errore (tutti i codici) e di manutenzione: obbligatorie | `front-error-pages` |
| template, blocchi, header/footer delle email | `front-mail` |
| controller, rotte, home, redirect della root | `front-routes` |
| un dato che serve a più viste | `front-shared-data` |

## 2. Flusso di lavoro

1. Leggi la skill del lavoro (tabella sopra).
2. Scrivi seguendo le sue regole (`rules/*.md`).
3. Lancia `bash scripts/check-all.sh <root-del-progetto>`.
4. Correggi ogni `FAIL`. Ogni riga indica la regola da leggere (`-> rules/x.md`).
5. Un `WARN` si valuta: o lo correggi o spieghi perché resta.

## 3. Le regole che valgono sempre

- Niente CSS/JS inline nelle Blade (`rules/no-inline.md`).
- HTML semantico e accessibile: tag con significato, un `<h1>`, input del tipo giusto con `tabindex` nei form, `alt` su ogni immagine, `rel="noopener noreferrer"` sui link esterni (`rules/html-markup.md`, skill `front-html`).
- Ciò che si usa due volte è un componente in `components/`, mai due copie (`rules/components-reuse.md`).
- `DESIGN.md` nella root è obbligatorio: si usa per colori, font, spaziature e componenti, e ogni modifica al design si riporta lì nella stessa modifica (`rules/design-md.md`).
- Direttive Blade, non PHP crudo (`rules/blade-directives.md`).
- Traduzioni: `@lang` per il testo, `{{ __() }}` negli attributi (`rules/translations.md`).
- Logica complessa nel controller o in un viewController, mai nella Blade (`rules/blade-logic.md`).
- Asset locali sempre con `Version::get()`, in produzione un solo file minificato (`rules/assets-versioning.md`).
- In un repo esistente con un'altra struttura: adattati e chiedi prima di spostare file.
