---
description: Riepilogo in italiano di quanto fatto su un ticket Jira, dai tuoi ultimi commit, pronto da incollare nei commenti del ticket
argument-hint: <codice-ticket>
---

Ticket: `$ARGUMENTS`. Se manca il codice, chiedilo e fermati.

## Regola d'oro

Un commento **in italiano**, rivolto a chi segue il ticket (cliente o PM): cosa è cambiato e cosa c'è da sapere, non come è stato implementato. Solo testo da incollare, senza premesse né saluti.

## Procedura

1. Trova i commit: tuoi (`git config user.email`), sul repository corrente e su quelli toccati nella sessione.
   - Prima quelli che citano il ticket: `git log --author="<email>" -i --grep="<ticket>" --pretty=format:"%h %ad %s%n%b" --date=short`.
   - Se nessuno lo cita, usa i tuoi ultimi commit legati al lavoro del ticket (aiutati con la sessione e, se il MCP di Jira è disponibile, con titolo e descrizione del ticket). Se non è chiaro quali siano, mostra l'elenco e chiedi conferma prima di scrivere.
2. Se serve capire un commit, guarda il diff (`git show --stat <hash>`), ma non riportare dettagli tecnici.
3. Scrivi il commento:
   - prima riga: codice e titolo del ticket (es. `ESP-123 – Ricerca nei select multipli`); il titolo prendilo dal MCP di Jira o dalla sessione, altrimenti chiedilo;
   - una riga che dice cosa è stato fatto;
   - un breve elenco puntato (`-`) delle modifiche visibili, raggruppate per area; niente nomi di file, classi o hash;
   - se ci sono, le note utili per chi verifica: dove guardare, cosa resta da fare, cosa non è ancora online (commit non pubblicati, deploy da fare);
   - se il lavoro è piccolo, bastano una o due righe senza elenco.
4. Restituisci solo il testo del commento. Non pubblicarlo su Jira se non te lo chiedono.
