---
description: Riepilogo breve in italiano di quanto fatto oggi, basato sui commit del giorno e sul contesto della sessione
---

## Regola d'oro

Un riepilogo di **massimo 50 parole**, in **italiano**, a un livello di dettaglio "cosa è cambiato per il progetto" — mai il dettaglio implementativo riga per riga (niente nomi di classi CSS, selettori, valori esadecimali, nomi di variabili/funzioni). Se oggi non è stato fatto molto, il riepilogo resta corto: non riempirlo con frasi di contorno.

## Procedura

1. Recupera i commit di oggi sul branch corrente: `git log --since=midnight --oneline --pretty=format:"%h %s"`.
2. Considera anche il contesto della conversazione in corso: cosa è stato realmente fatto o deciso oggi (skill create/modificate, bug risolti, decisioni prese), anche se non ancora committato — i commit da soli possono non raccontare il perché di un cambiamento.
3. Scrivi un riepilogo unico che unisce i due segnali, rispettando questi vincoli:
   - **Non troppo tecnico**: descrivi il "cosa" e il "perché" a livello di funzionalità/skill/documentazione, mai l'implementazione (no classi, selettori, colori, righe di codice).
   - **Non troppo vago**: cita concretamente le cose fatte (es. "aggiunta la skill X per gestire Y"), non frasi generiche tipo "sono state apportate diverse migliorie".
   - **Massimo 50 parole.**
   - Se i cambiamenti di oggi sono pochi o nulli, dillo in una riga breve — non inventare contenuto e non aggiungere riempitivo per arrivare al limite di parole.
   - **Se la giornata è stata dedicata a un solo filone di lavoro** (es. tutti i commit/attività ruotano attorno a una singola migrazione, un solo refactor, una sola feature), non elencare ogni singolo passaggio: riassumi con l'etichetta del filone stesso (es. "migrazione del contenuto da X a Y") invece di una lista di dettagli. Solo se la giornata ha toccato attività diverse e scollegate tra loro elenca i temi separatamente.
