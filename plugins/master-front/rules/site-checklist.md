# Regola: cose che il sito deve avere (non le gestisce questo plugin)

Il plugin le **verifica soltanto** (`/master-front:site-checklist`, `scripts/check-site.sh`): non crea né modifica codice. Ognuna ha il suo procedimento.

| Cosa | Il sito deve avere | Procedimento |
|---|---|---|
| sitemap | sitemap XML generate (`sitemaps/` o `sitemap.xml` nella root web) e la riga `Sitemap:` in `robots.txt` | skill **master-sitemap** (Enesi Academy, forum Claude Code: crea il comando Artisan); generica: `claude-seo:seo-sitemap` |
| structured data | JSON-LD (`<script type="application/ld+json">`, es. componente `StructuredData`, `Websites::current('structured_data')`) | nessun procedimento Enesi; generica: `claude-seo:seo-schema` |
| llms.txt | `llms.txt` nella root web | nessun procedimento Enesi; generica: `claude-seo:seo-geo`, `claude-seo:seo-agentic` |
| robots.txt | `robots.txt` nella root web, senza `Disallow: /` in produzione | `master-install` lo prevede all'installazione; generica: `claude-seo:seo-technical` |
| SEO on-page | title, description, canonical, og:tags in ogni action (`meta.md`) | questo plugin: `front-meta` + `scripts/check-meta.sh`; audit: `claude-seo:seo-audit`, report Enesi `seo-geo-aeo:seo-report`, doc Academy «SEO Tecnica» |
| Core Web Vitals | LCP, INP, CLS misurati sul sito online | nessun procedimento Enesi; generica: `agent-skills:webperf`, `claude-seo:seo-performance` |

Verifica: `scripts/check-site.sh` (solo presenza; i Core Web Vitals si misurano, non si leggono dal codice).
