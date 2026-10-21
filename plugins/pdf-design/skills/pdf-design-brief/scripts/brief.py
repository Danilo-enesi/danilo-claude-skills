"""Write design/DESIGN.md, the short brief a builder reads first, from the pdf-design JSON files.

Usage: python brief.py [--out design] [--max-lines 100]
Reads tokens.json, fonts.json, sections.json, images.json, interpretation.json (optional).
Project-specific instructions go in interpretation.json -> "notes" (list of markdown lines).
Prints the path and line count; fails if the brief exceeds --max-lines.
"""
import argparse, json, os, sys

WEB_SAFE = {'Arial', 'Helvetica', 'Verdana', 'Georgia', 'Times New Roman', 'Courier New', 'Tahoma', 'Trebuchet MS'}


def load(path, default=None):
    return json.load(open(path, encoding='utf-8')) if os.path.exists(path) else default


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default='design')
    ap.add_argument('--max-lines', type=int, default=100)
    a = ap.parse_args()
    D = a.out
    t = load(f'{D}/tokens.json')
    fonts = load(f'{D}/fonts.json', [])
    sections = load(f'{D}/sections.json', {})
    images = load(f'{D}/images.json', [])
    it = load(f'{D}/interpretation.json', {})
    roles, names, stacks = it.get('colors', {}), it.get('sections', {}), it.get('font_stacks', {})
    c = t['container']

    L = ['# Design brief', '',
         'Read this and `tokens.json` first. Open `sections/*.png` one at a time, only for the section you build.', '',
         '## Design', '',
         f"- Content column: **{c['width_px']} px** ({c['width_pt']} pt in the PDF). Scale: `px = pt × {t['px_per_pt']}`.",
         '', '**Palette**', '', '| hex | role |', '|---|---|']
    L += [f"| `{x['hex']}` | {roles.get(x['hex'], '? (' + ', '.join(x['as']) + ')')} |" for x in t['colors']]
    L += ['', '**Fonts**', '']
    for f in fonts:
        fam = f['identified_as'] or f['pdf_name']
        L.append(f"- {fam} {f['style'] or ''} — identified by {f['confidence']}"
                 + (f" · stack `{stacks[fam]}`" if fam in stacks else ''))
    L += ['', '**Type scale** (pt → px): ' + ' · '.join(f"{s['pt']}→**{s['px']}**" for s in t['font_sizes'])]
    if t['spacing']:
        L += ['', '**Frequent vertical gaps** (px): ' + ', '.join(str(s['px']) for s in t['spacing'][:6])]
    L += ['', '**Sections**', '', '| section | PNG | bbox (pt) |', '|---|---|---|']
    for items in sections.values():
        for s in items:
            key = os.path.basename(s['file'])[:-4]
            L.append(f"| {names.get(key, '?')} | `{s['file']}` | {', '.join(str(v) for v in s['bbox'])} |")
    if images:
        L += ['', '**Images** (`assets/`): ' + ', '.join(f"`{i['file'][7:]}`" for i in images)]

    warn = [f"Font {f['identified_as']} is not web-safe: give it a fallback stack" for f in fonts
            if f['identified_as'] and f['identified_as'] not in WEB_SAFE]
    warn += [f"Font `{f['pdf_name']}` not identified (vendor {f['vendor']})" for f in fonts if f['confidence'] == 'unknown']
    warn += [f"Font {f['identified_as']} deduced from its metrics fingerprint, not confirmed by metadata" for f in fonts
             if f['confidence'].startswith('fingerprint')]
    L += ['', '**Warnings**', ''] + [f'- {w}' for w in dict.fromkeys(warn)] if warn else []
    if it.get('notes'):
        L += ['', '## Project notes', ''] + it['notes']
    if it.get('pending'):
        L += ['', '## Pending', ''] + [f'- {p}' for p in it['pending']]

    open(f'{D}/DESIGN.md', 'w', encoding='utf-8', newline='\n').write('\n'.join(L) + '\n')
    print(f'{D}/DESIGN.md · {len(L)} lines')
    if len(L) > a.max_lines:
        sys.exit(f'too long: shorten interpretation.json notes/pending (limit {a.max_lines})')


if __name__ == '__main__':
    main()
