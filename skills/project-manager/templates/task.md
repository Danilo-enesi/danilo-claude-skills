# Voce di checklist (§2 Piano di docs/asked/<slug>.md)

Usa i sotto-campi solo quando aggiungono informazione reale: una fase documentale
o banale può restare `- [ ] ⏳ Fase N — <nome>` senza altro. Non gonfiare fasi
semplici solo per riempire il template.

```markdown
- [ ] ⏳ **Fase N — <nome>**
  - Acceptance: <condizione osservabile, presa dai Criteri di accettazione della Comprensione>
  - Verify: <tier (smoke|focused|full) + comando/pilastro, oppure "n.a. — fase documentale">
  - File/moduli attesi: <elenco indicativo, usato anche per dimensionare il tier di verifica>
```

`Verify` è un contratto: lo scrive chi pianifica (tu, PM, al momento dell'handoff),
non lo inventa chi verifica dopo. Vedi `reference/verification.md` per come il tier
viene scelto in base a "File/moduli attesi".
