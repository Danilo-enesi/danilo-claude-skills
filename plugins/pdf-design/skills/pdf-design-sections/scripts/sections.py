"""Split each page into horizontal sections using the vertical gaps between elements, and crop them.

Usage: python sections.py [--out design] [--gap 6] [--divider 8]
Needs info.json, text/, shapes/, images.json (extract.py) and tokens.json (tokens.py).
Writes design/sections/page-N-sK.png + design/sections.json, prints the file list.
"""
import argparse, glob, json, os, sys
import pymupdf


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default='design')
    ap.add_argument('--gap', type=float, default=6, help='pt of empty space that splits two sections')
    ap.add_argument('--divider', type=float, default=8, help='sections thinner than this (pt) are glued to the next')
    a = ap.parse_args()
    D = a.out
    info = json.load(open(f'{D}/info.json'))
    cont = json.load(open(f'{D}/tokens.json'))['container']['bbox_pt']
    cw = cont[2] - cont[0]
    images = json.load(open(f'{D}/images.json'))
    doc = pymupdf.open(info['source'])
    os.makedirs(f'{D}/sections', exist_ok=True)
    for f in glob.glob(f'{D}/sections/page-*-s*.png'):  # only our own previous crops
        os.remove(f)
    out = {}
    for i, p in enumerate(doc):
        n = i + 1
        boxes = [b['bbox'] for b in json.load(open(f'{D}/text/page-{n}.json', encoding='utf-8'))]
        boxes += [s['bbox'] for s in json.load(open(f'{D}/shapes/page-{n}.json'))
                  if s['bbox'][2] - s['bbox'][0] < 0.95 * cw]  # backgrounds would merge everything
        boxes += [im['bbox'] for im in images if im['page'] == n]
        spans = []
        for _, y0, _, y1 in sorted(boxes, key=lambda b: b[1]):
            if spans and y0 - spans[-1][1] < a.gap:
                spans[-1][1] = max(spans[-1][1], y1)
            else:
                spans.append([y0, y1])
        merged = []
        for s in spans:
            if merged and merged[-1][1] - merged[-1][0] < a.divider:
                merged[-1][1] = s[1]
            else:
                merged.append(s)
        out[n] = []
        for k, (y0, y1) in enumerate(merged, 1):
            name, r = f'page-{n}-s{k}.png', [cont[0], max(y0 - 2, 0), cont[2], min(y1 + 2, p.rect.height)]
            p.get_pixmap(dpi=info['dpi'], clip=pymupdf.Rect(r)).save(f'{D}/sections/{name}')
            out[n].append({'file': f'sections/{name}', 'bbox': [round(v, 1) for v in r]})
    json.dump(out, open(f'{D}/sections.json', 'w'), indent=1)
    for n, ss in out.items():
        print(f'page {n}: {len(ss)} sections: ' + ' '.join(x['file'][9:] for x in ss))


if __name__ == '__main__':
    main()
