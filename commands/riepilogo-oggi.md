---
description: Riepilogo di oggi in una sola frase in italiano, pronta da incollare in una textarea
---

## Regola d'oro

Rispondi con **una sola frase in italiano**, in testo semplice (niente markdown, elenchi, virgolette o premesse), che dica le cose **più importanti** fatte oggi. Una frase è il massimo, non l'obiettivo: se c'è poco da dire bastano quattro parole (anche un'espressione nominale, es. "Fix anteprima allegati PDF").

## Procedura

1. Raccogli quanto fatto oggi:
   - il contesto della conversazione in corso (vale anche il lavoro non ancora committato e quello su altri repository toccati nella sessione);
   - i commit di oggi di ogni repository toccato: `git -C <repo> log --since=midnight --pretty=format:"%h %s"`.
2. Tieni solo ciò che conta per il progetto o per il cliente: funzionalità, bug risolti, riorganizzazioni visibili. Scarta passaggi intermedi, tentativi annullati, commit e test.
3. Scrivi la frase:
   - **né tecnica** (niente nomi di file, classi, campi, comandi) **né vaga** (niente "varie migliorie");
   - se il lavoro è uno solo, usa il nome del filone invece di elencarne i passaggi;
   - se lo stesso lavoro è stato fatto su più progetti, nominali una volta sola alla fine (es. "... su Espango e Agipompe");
   - solo se oggi si è lavorato su ticket Jira (citati nella sessione o letti dal MCP di Jira), aggiungi la chiave del ticket accanto al lavoro corrispondente (es. "ESP-123"); altrimenti non nominare Jira.
4. Restituisci solo la frase.
