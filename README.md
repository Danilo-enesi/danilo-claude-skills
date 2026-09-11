# danilo-claude-skills

Marketplace personale di Claude Code con le mie skill, comandi e sub-agenti.

Questo repo è al tempo stesso un **marketplace** e un **plugin** di Claude
Code: il marketplace punta a un unico plugin (`./`) che raggruppa tutto il
contenuto.

## Convenzione linguistica

- Documentazione del repo (README, commit, note): **italiano**.
- Definizione delle skill (`SKILL.md`: nome, `description`, contenuto e
  istruzioni): **inglese**, per convenzione standard di Claude Code — la
  `description` viene letta dal modello per decidere quando attivare la
  skill, e l'inglese garantisce coerenza col resto dell'ecosistema.

## Struttura

```
danilo-claude-skills/
├── .claude-plugin/
│   ├── marketplace.json   ← definisce il marketplace e lista il plugin
│   └── plugin.json        ← metadata del plugin
├── skills/                ← skill (SKILL.md + risorse, in inglese)
├── commands/               ← comandi slash (*.md)
├── agents/                 ← sub-agenti (*.md)
└── README.md
```

## Installazione

Da un progetto qualsiasi, in Claude Code:

```
/plugin marketplace add danilo/danilo-claude-skills
/plugin install danilo-claude-skills
```

Oppure in locale (percorso assoluto al repo clonato):

```
/plugin marketplace add C:\Users\danilo\Dev\danilo-claude-skills
/plugin install danilo-claude-skills
```

## Skill disponibili

| Skill | Descrizione |
|---|---|
| `project-manager` | Comando `/project-manager`: modalità operativa per implementazioni complesse da capire e validare bene prima di eseguire. Un unico flusso a 5 fasi (Comprensione → Strategia/Esecuzione → Verifica → Validazione → Chiusura), con stato persistito su disco e delega ai worker. |
| `subagent-empowerment` | Checklist per decidere quanto "potere" dare a un sottoagente prima di delegargli lavoro: quale modello, quali skill fargli caricare, quali MCP autorizzargli, se può scrivere su CLAUDE.md, con tetti di concorrenza. |
| `master-core-fields` | Come creare, valorizzare e personalizzare i campi (Field) dei form admin del Master Laravel Enesi (`$form->addField(...)`). Guida concettuale + script dedicati (`scripts/`) che validano struttura del Field custom e regola "0 JS/CSS inline". |
| `master-front-rules` | Regole di setup del layout del front (`private/front/Main/Views/base/`): stack `head`/`scripts`, `Meta::render()`, cookie banner EPP, condivisione dati cross-Blade (view composer / `Front::loadSharedContent()`). |
| `master-page-content` | Sistema di blocchi di contenuto DB-driven (`Contents` field, `page_contents`/`blog_contents`/...): come installarlo su un modulo nuovo, estendere un tipo di blocco, scrivere il rendering frontend. |
| `template-to-blade` | Trasforma un HTML statico di prototipo (`template/*.html`) in una view Blade del front, replicando markup/classi 1:1 ed estraendo CSS/JS chirurgicamente (mai inline). |
| `master-code-review` | Revisione di qualità del codice PHP/Laravel del Master: esegue script deterministici (`scripts/`) per le convenzioni strutturali/comportamentali, poi valuta best practice Laravel e DRY/SOLID. Sola lettura, solo segnala. |
| `commit-to-main` | Come creare commit Git: sempre diretti sul branch corrente (niente branch/PR), sempre a file intero (mai frammentati), messaggio in italiano e conciso, raggruppati per funzionalità. Al termine restituisce una tabella file→motivo. |
| `keep-it-simple` | Criterio per i commenti nel codice: solo dove servono davvero, brevi (1-2 righe), mai una cronologia di modifiche — solo stato attuale o il perché di una decisione. |

## Comandi disponibili

| Comando | Descrizione |
|---|---|
| `riepilogo-oggi` | Genera un riepilogo breve (max 50 parole, in italiano) di quanto fatto oggi, basandosi sui commit del giorno e sul contesto della sessione. |

I sub-agenti (`agents/`) sono al momento vuoti (solo `.gitkeep`).

## Aggiungere una nuova skill

1. Creare `skills/<skill-name>/SKILL.md` con frontmatter `name` e
   `description` **in inglese**.
2. Aggiungere nella stessa cartella le risorse necessarie alla skill.
3. Aggiornare la versione in `.claude-plugin/plugin.json`.
4. Commit + push.

## Aggiungere un comando o un sub-agente

- Comandi: `commands/<nome>.md`
- Sub-agenti: `agents/<nome>.md`
