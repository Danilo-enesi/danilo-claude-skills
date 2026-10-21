---
name: pdf-design-brief
author: Danilo-enesi
description: Write design/DESIGN.md, the short brief (max 100 lines) an AI builder reads before building a design from a PDF - container and px scale, palette with roles, fonts, type scale, sections with PNG and bbox, warnings, project notes and pending items. Use after the pdf-design extraction steps when the work will be built or handed to another agent ("prepare the design for another agent", "write the design brief"). Only writes the brief.
---

# pdf-design-brief

**Rule:** the brief is generated, not hand-written. Your judgement goes in `interpretation.json`; the script formats it.

## Steps

1. Look at `design/pages/page-N.png` once (a section PNG only if a block is unclear).
2. Write `design/interpretation.json` (all keys optional):
   ```json
   {
     "colors": {"#e18629": "Accent: buttons, top bar", "#333333": "Body text"},
     "font_stacks": {"Helvetica Neue": "'Helvetica Neue', Helvetica, Arial, sans-serif"},
     "sections": {"page-1-s1": "Header", "page-1-s2": "Hero image"},
     "notes": ["- Build it inside `templates/foo/`, following `templates/bar/`."],
     "pending": ["Card images are placeholders"]
   }
   ```
   - `colors` keys match `tokens.json`; `font_stacks` keys match the identified family; `sections` keys are the PNG names without `.png`.
   - `notes`: project-specific instructions (markdown lines), found by reading the target project. What you cannot deduce goes in `pending`, never guessed.
3. Generate (`scripts/` is relative to this skill's directory):
   ```
   python -I scripts/brief.py --out design
   ```
4. If it fails for length, shorten `notes`/`pending`, not the generated parts.

## Output

`design/DESIGN.md`: Design (container, palette, fonts, type scale, gaps, sections, images, warnings) + Project notes + Pending. Rows showing `?` are uninterpreted: fill `interpretation.json` and re-run.

## Notes

- Warnings are automatic: non web-safe fonts, unidentified fonts, fonts known only by fingerprint.
- Next: `pdf-design-recreate` (it reads this brief), or hand `design/` to the builder.
