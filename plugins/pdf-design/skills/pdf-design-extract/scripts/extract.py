"""Extract raw design data from a PDF into a work folder.

Usage: python extract.py <file.pdf> [--out design] [--dpi 150] [--only info,pages,text,shapes,images,svg]
Prints only counts. Everything goes to files.
"""
import argparse, json, os, sys
import pymupdf

STEPS = ['info', 'pages', 'text', 'shapes', 'images', 'svg']
r1 = lambda b: [round(v, 1) for v in b]
hexc = lambda c: '#%02x%02x%02x' % tuple(round(v * 255) for v in c[:3]) if c else None


def info(doc, out, a):
    pages = [{'page': i + 1, 'width': round(p.rect.width, 2), 'height': round(p.rect.height, 2)} for i, p in enumerate(doc)]
    json.dump({'source': os.path.abspath(a.pdf), 'dpi': a.dpi, 'pages': pages}, open(f'{out}/info.json', 'w'), indent=1)
    for x in pages[:10]:
        print(f"info    page {x['page']}: {x['width']} x {x['height']} pt")


def pages(doc, out, a):
    for i, p in enumerate(doc):
        p.get_pixmap(dpi=a.dpi).save(f'{out}/pages/page-{i + 1}.png')
    print(f'pages   {len(doc)} PNG at {a.dpi} dpi')


def text(doc, out, a):
    for i, p in enumerate(doc):
        blocks = []
        for b in p.get_text('dict')['blocks']:
            if b['type'] != 0:
                continue
            spans = [{'text': s['text'], 'font': s['font'], 'size': round(s['size'], 1),
                      'bold': bool(s['flags'] & 16), 'italic': bool(s['flags'] & 2),
                      'color': f"#{s['color']:06x}", 'bbox': r1(s['bbox'])}
                     for l in b['lines'] for s in l['spans'] if s['text'].strip()]
            if spans:
                blocks.append({'bbox': r1(b['bbox']), 'spans': spans})
        json.dump(blocks, open(f'{out}/text/page-{i + 1}.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
        print(f'text    page {i + 1}: {len(blocks)} blocks')


def shapes(doc, out, a):
    for i, p in enumerate(doc):
        s = [{'type': d['type'], 'bbox': r1(d['rect']), 'fill': hexc(d.get('fill')),
              'stroke': hexc(d.get('color')), 'width': d.get('width')} for d in p.get_drawings()]
        json.dump(s, open(f'{out}/shapes/page-{i + 1}.json', 'w'), indent=1)
        print(f'shapes  page {i + 1}: {len(s)} shapes')


def images(doc, out, a):
    seen, rects = set(), []
    for i, p in enumerate(doc):
        for img in p.get_images(full=True):
            xref, smask = img[0], img[1]
            if xref not in seen:
                seen.add(xref)
                if smask:  # transparency is a separate soft-mask image: recombine as PNG
                    pix = pymupdf.Pixmap(pymupdf.Pixmap(doc, xref), pymupdf.Pixmap(doc, smask))
                    name = f'page-{i + 1}-img-{xref}-{pix.width}x{pix.height}.png'
                    pix.save(f'{out}/assets/{name}')
                else:
                    x = doc.extract_image(xref)
                    name = f"page-{i + 1}-img-{xref}-{x['width']}x{x['height']}.{x['ext']}"
                    open(f'{out}/assets/{name}', 'wb').write(x['image'])
            name = next(f for f in os.listdir(f'{out}/assets') if f'-img-{xref}-' in f)
            rects += [{'page': i + 1, 'file': f'assets/{name}', 'bbox': r1(r)} for r in p.get_image_rects(xref)]
    json.dump(rects, open(f'{out}/images.json', 'w'), indent=1)
    print(f'images  {len(seen)} files, {len(rects)} placements')


def svg(doc, out, a):
    for i, p in enumerate(doc):
        open(f'{out}/svg/page-{i + 1}.svg', 'w', encoding='utf-8').write(p.get_svg_image())
    print(f'svg     {len(doc)} files')


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('pdf')
    ap.add_argument('--out', default='design')
    ap.add_argument('--dpi', type=int, default=150)
    ap.add_argument('--only', default=','.join(STEPS))
    ap.add_argument('--force', action='store_true', help='write into a non-empty folder not created by this script')
    a = ap.parse_args()
    # never overwrite someone else's folder: only reuse an empty one or one we made (has info.json)
    if os.path.isdir(a.out) and os.listdir(a.out) and not os.path.exists(f'{a.out}/info.json') and not a.force:
        sys.exit(f'{a.out} is not empty and was not created by extract.py: choose another --out or pass --force')
    for d in ('pages', 'text', 'shapes', 'assets', 'svg'):
        os.makedirs(f'{a.out}/{d}', exist_ok=True)
    doc = pymupdf.open(a.pdf)
    for step in a.only.split(','):
        globals()[step](doc, a.out, a)


if __name__ == '__main__':
    main()
