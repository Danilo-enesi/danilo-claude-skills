---
description: Verifica veloce, in sola lettura, delle cose che il sito deve avere (sitemap, structured data, llms.txt, robots.txt, SEO, Core Web Vitals) e indica il procedimento che se ne occupa
argument-hint: "[root del progetto]"
---

## Regola d'oro

Solo verifica: **non creare né modificare codice**, nemmeno per ciò che manca. Per ogni mancanza indica il procedimento che se ne occupa.

## Procedura

1. Root del progetto: `$ARGUMENTS`, altrimenti la root git della cartella corrente.
2. Lancia `bash "${CLAUDE_PLUGIN_ROOT}/scripts/check-site.sh" <root>`. Non leggere altro codice: basta l'output.
3. Rispondi con una tabella `cosa → OK / manca → procedimento`, prendendo il procedimento da `${CLAUDE_PLUGIN_ROOT}/rules/site-checklist.md`.
4. Dove il procedimento è «nessun procedimento Enesi», dillo esplicitamente: va creato.
