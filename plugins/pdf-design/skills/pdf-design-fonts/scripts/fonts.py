"""Identify the fonts of a PDF: metadata first, metrics fingerprint only as fallback.

Usage: python fonts.py <file.pdf> [--out design]
Order of evidence (stops at the first that answers):
  1. metadata  - family/full/PostScript names in the embedded font, or in the PDF font dicts
  2. metadata  - a known copyright-notice signature, or a known family named in the font's
                 copyright/trademark/manufacturer texts
  3. fingerprint - x-height + cap-height (+ OS/2 vendor) matched against KNOWN
  4. unknown   - report the fingerprint and ask the user; never guess by looking at glyphs
Writes design/fonts.json and prints one line per distinct font.
"""
import argparse, json, re, struct, sys
import pymupdf

# (x-height, cap-height) per 1000 em + OS/2 vendor id. Source: the fonts' own OS/2 / AFM data.
KNOWN = {
    'Helvetica Neue': (517, 714, 'LINO'), 'Helvetica': (523, 718, 'LINO'), 'Arial': (519, 716, 'TMC'),
    'Times New Roman': (447, 662, 'TMC'), 'Georgia': (481, 693, 'TMC'), 'Verdana': (545, 727, 'TMC'),
    'Courier New': (423, 571, 'TMC'), 'Roboto': (528, 711, 'GOOG'), 'Open Sans': (535, 714, 'GOOG'),
    'Inter': (546, 727, 'RSMS'), 'Lato': (506, 717, 'tyPL'),
}
TOLERANCE = 5
# Copyright-notice signatures that survive when a PDF exporter renames the font.
# Add one only from a font file you have actually inspected (note where it came from).
NOTICES = {
    'Helvetica Neue': ['1981, 1982, 1983, 1989 and 1993, Linotype'],  # macOS HelveticaNeue.ttc
}
# name table ids worth keeping: 0 copyright, 1 family, 3 unique id, 4 full name, 6 PostScript name,
# 7 trademark, 8 manufacturer, 9 designer, 16/17 typographic family/subfamily
NAME_IDS = {0: 'copyright', 1: 'family', 2: 'style', 3: 'unique_id', 4: 'full_name', 6: 'postscript',
            7: 'trademark', 8: 'manufacturer', 9: 'designer', 16: 'typo_family', 17: 'typo_style'}
ANON = re.compile(r'^(font[0-9a-f]{6,}|F\d+|T\d+|TT\d+|C\d+_\d+|[A-Z]{6}\+.*)$', re.I)


def meaningful(name):
    return bool(name) and not ANON.match(name.strip())


def sfnt_tables(buf):
    if buf[:4] not in (b'\x00\x01\x00\x00', b'OTTO', b'true'):
        return None
    n = struct.unpack('>H', buf[4:6])[0]
    return {buf[12 + 16 * i:16 + 16 * i].decode('latin-1'): struct.unpack('>II', buf[20 + 16 * i:28 + 16 * i])
            for i in range(n)}


def sfnt_info(buf):
    t = sfnt_tables(buf)
    if not t:
        return {}, {}
    names, metrics = {}, {}
    if 'name' in t:
        off, ln = t['name']
        nt = buf[off:off + ln]
        cnt, so = struct.unpack('>HH', nt[2:6])
        for j in range(cnt):
            pid, _, _, nid, l, o = struct.unpack('>6H', nt[6 + 12 * j:18 + 12 * j])
            if nid in NAME_IDS and NAME_IDS[nid] not in names:
                s = nt[so + o:so + o + l]
                names[NAME_IDS[nid]] = (s.decode('utf-16-be', 'replace') if pid in (0, 3) else s.decode('latin-1')).strip()
    upem = struct.unpack('>H', buf[t['head'][0] + 18:t['head'][0] + 20])[0] if 'head' in t else 1000
    if 'OS/2' in t:
        o, ln = t['OS/2']
        metrics['vendor'] = buf[o + 58:o + 62].decode('latin-1').strip()
        metrics['weight'] = struct.unpack('>H', buf[o + 4:o + 6])[0]
        if ln >= 90:  # OS/2 version 2+ carries x-height and cap-height
            xh, cap = struct.unpack('>hh', buf[o + 86:o + 90])
            metrics['x_height'], metrics['cap_height'] = round(xh * 1000 / upem), round(cap * 1000 / upem)
    return names, metrics


def cff_strings(buf):
    """Bare CFF/Type1 fonts: keep readable strings (notice, full name), where foundries put their names."""
    runs = re.findall(rb'[\x20-\x7e]{6,}', buf[:20000])
    keep = [r.decode() for r in runs if re.search(rb'(?i)copyright|trademark|\(c\)|reserved|[A-Z][a-z]+ ?[A-Z]?[a-z]*', r)]
    return {'strings': ' | '.join(keep[:6])} if keep else {}


def pdf_dict_info(doc, xref):
    """BaseFont plus FontDescriptor names/metrics (FontFamily is often present even when the file is renamed)."""
    out = {}
    k, v = doc.xref_get_key(xref, 'BaseFont')
    if k == 'name':
        out['base_font'] = v.lstrip('/').split('+', 1)[-1]
    desc = None
    k, v = doc.xref_get_key(xref, 'FontDescriptor')
    if k == 'xref':
        desc = int(v.split()[0])
    else:
        k, v = doc.xref_get_key(xref, 'DescendantFonts')
        m = re.search(r'(\d+) 0 R', v or '')
        if m:
            k, v = doc.xref_get_key(int(m.group(1)), 'FontDescriptor')
            desc = int(v.split()[0]) if k == 'xref' else None
    if desc:
        for key, name in (('FontFamily', 'font_family'), ('FontName', 'font_name'),
                          ('XHeight', 'x_height'), ('CapHeight', 'cap_height')):
            k, v = doc.xref_get_key(desc, key)
            if k in ('string', 'name'):
                out[name] = v.strip('()/').split('+', 1)[-1]
            elif k == 'int':
                out[name] = int(v)
    return out


def from_metadata(names, pdf):
    """Return (family, source) from names that are not anonymized placeholders."""
    for key in ('typo_family', 'family', 'full_name', 'postscript'):
        if meaningful(names.get(key)):
            return names[key], f'font file name table ({key})'
    for key in ('font_family', 'base_font', 'font_name'):
        if meaningful(pdf.get(key)):
            return pdf[key], f'PDF font dictionary ({key})'
    text = ' '.join(names.get(k, '') for k in ('copyright', 'trademark', 'manufacturer', 'designer', 'unique_id', 'strings'))
    for family, sigs in NOTICES.items():
        if any(s in text for s in sigs):
            return family, 'font file copyright notice (known signature)'
    hits = sorted((n for n in KNOWN if re.search(r'\b' + re.escape(n) + r'\b', text)), key=len, reverse=True)
    if hits:
        return hits[0], 'font file notices (copyright/trademark)'
    return None, None


def from_fingerprint(xh, cap, vendor):
    """Known fonts within tolerance, closest first; a vendor match wins ties (Helvetica Neue vs Arial)."""
    if xh is None or cap is None:
        return []
    near = sorted((abs(kx - xh) + abs(kc - cap), kv != vendor, n) for n, (kx, kc, kv) in KNOWN.items()
                  if abs(kx - xh) <= TOLERANCE and abs(kc - cap) <= TOLERANCE)
    return [n for *_, n in near]


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('pdf')
    ap.add_argument('--out', default='design')
    a = ap.parse_args()
    doc = pymupdf.open(a.pdf)
    fonts, seen = {}, set()
    for page in doc:
        for xref, ext, ftype, basefont, *_ in page.get_fonts(full=True):
            if xref in seen:
                continue
            seen.add(xref)
            names, metrics = {}, {}
            try:
                buf = doc.extract_font(xref)[3]
                names, metrics = sfnt_info(buf)
                if not names and buf:
                    names = cff_strings(buf)
            except Exception:
                pass
            pdf = pdf_dict_info(doc, xref)
            for k in ('x_height', 'cap_height'):
                metrics.setdefault(k, pdf.get(k))
            family, source = from_metadata(names, pdf)
            cands = [] if family else from_fingerprint(metrics.get('x_height'), metrics.get('cap_height'), metrics.get('vendor'))
            if family:
                confidence = 'metadata'
            elif cands:
                confidence = 'fingerprint+vendor' if KNOWN[cands[0]][2] == metrics.get('vendor') else 'fingerprint'
                source = 'x-height/cap-height' + (' + OS/2 vendor' if confidence == 'fingerprint+vendor' else '')
            else:
                confidence, source = 'unknown', None
            pdf_name = basefont.split('+', 1)[-1]
            key = (pdf_name, family, names.get('style'), metrics.get('weight'))
            f = fonts.setdefault(key, {
                'pdf_name': pdf_name, 'type': ftype, 'style': names.get('style'), 'weight': metrics.get('weight'),
                'identified_as': family or (cands[0] if cands else None), 'confidence': confidence, 'source': source,
                'candidates': cands, 'vendor': metrics.get('vendor'),
                'x_height': metrics.get('x_height'), 'cap_height': metrics.get('cap_height'),
                'metadata': {**{k: v for k, v in names.items() if v}, **{k: v for k, v in pdf.items() if isinstance(v, str)}},
                'subsets': 0})
            f['subsets'] += 1
    rows = list(fonts.values())
    json.dump(rows, open(f'{a.out}/fonts.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    for f in rows:
        who = f['identified_as'] or 'UNKNOWN'
        alt = f" (also: {', '.join(f['candidates'][1:])})" if len(f['candidates']) > 1 else ''
        print(f"{f['pdf_name'][:28]:28} {str(f['style'] or ''):10} -> {who}{alt} [{f['confidence']}: {f['source']}] "
              f"vendor={f['vendor']} xh={f['x_height']} cap={f['cap_height']} x{f['subsets']}")
        if f['confidence'] != 'metadata' and f['metadata'].get('copyright'):
            print(f"  notice: {' '.join(f['metadata']['copyright'].split())[:160]}")


if __name__ == '__main__':
    main()
