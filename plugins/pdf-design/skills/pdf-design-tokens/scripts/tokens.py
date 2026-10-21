"""Build design tokens from the files written by extract.py (and fonts.py if present).

Usage: python tokens.py [--out design] [--target-width 600] [--container x0,x1]
--target-width: real width in px of the content column (e.g. 600 for an email, 1200 for a site).
                Without it 1pt = 1.333px (CSS 96dpi).
--container:    content column in pt, if auto-detection picks the wrong element.
Writes design/tokens.json and prints a short summary.
"""
import argparse, glob, json, os, sys
from collections import Counter


def load(path, default=None):
    return json.load(open(path, encoding='utf-8')) if os.path.exists(path) else default


def detect_container(info, images, shapes):
    """Widest placed image (a full-bleed hero spans the column), else widest shape narrower than the page."""
    page_w = info['pages'][0]['width']
    imgs = [i['bbox'] for i in images if i['bbox'][2] - i['bbox'][0] < 0.95 * page_w]
    if imgs:
        return max(imgs, key=lambda b: b[2] - b[0])
    boxes = [s['bbox'] for s in shapes if s['bbox'][2] - s['bbox'][0] < 0.9 * page_w]
    return max(boxes, key=lambda b: b[2] - b[0]) if boxes else [0, 0, page_w, 0]


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('--out', default='design')
    ap.add_argument('--target-width', type=float)
    ap.add_argument('--container')
    a = ap.parse_args()
    D = a.out
    info = load(f'{D}/info.json')
    blocks = [b for f in sorted(glob.glob(f'{D}/text/page-*.json')) for b in load(f)]
    spans = [s for b in blocks for s in b['spans']]
    shapes = [s for f in sorted(glob.glob(f'{D}/shapes/page-*.json')) for s in load(f)]
    images = load(f'{D}/images.json', [])
    fonts = load(f'{D}/fonts.json', [])

    if a.container:
        x0, x1 = map(float, a.container.split(','))
        cont = [x0, 0, x1, 0]
    else:
        cont = detect_container(info, images, shapes)
    cw = cont[2] - cont[0]
    ppt = a.target_width / cw if a.target_width else 96 / 72
    px = lambda v: round(v * ppt)

    colors = Counter()
    kinds = {}
    for s in spans:
        colors[s['color']] += 1
        kinds.setdefault(s['color'], set()).add('text')
    for s in shapes:
        for k in ('fill', 'stroke'):
            if s[k]:
                colors[s[k]] += 1
                kinds.setdefault(s[k], set()).add(k)

    family = {f['pdf_name']: f.get('identified_as') for f in fonts}
    fcount = Counter((s['font'], 'bold' if s['bold'] else 'regular', s['italic']) for s in spans)
    sizes = Counter(s['size'] for s in spans)
    # vertical gaps between consecutive text blocks, top to bottom
    ys = sorted((b['bbox'][1], b['bbox'][3]) for b in blocks)
    gaps = Counter(round(ys[i + 1][0] - ys[i][1]) for i in range(len(ys) - 1) if ys[i + 1][0] - ys[i][1] > 0.5)

    tokens = {
        'px_per_pt': round(ppt, 4),
        'container': {'bbox_pt': [round(v, 1) for v in cont], 'width_pt': round(cw, 1), 'width_px': px(cw),
                      'source': 'manual' if a.container else 'auto'},
        'colors': [{'hex': c, 'uses': n, 'as': sorted(kinds[c])} for c, n in colors.most_common(12)],
        'fonts': [{'pdf_name': f, 'family': family.get(f), 'weight': w, 'italic': i, 'uses': n}
                  for (f, w, i), n in fcount.most_common()],
        'font_sizes': [{'pt': s, 'px': px(s), 'uses': sizes[s]} for s in sorted(sizes)],
        'spacing': [{'pt': g, 'px': px(g), 'uses': n} for g, n in gaps.most_common(8)],
    }
    json.dump(tokens, open(f'{D}/tokens.json', 'w', encoding='utf-8'), ensure_ascii=False, indent=1)
    print(f"container {tokens['container']['bbox_pt']} = {tokens['container']['width_px']}px "
          f"({tokens['container']['source']}) · 1pt = {ppt:.3f}px")
    print(f"colors {len(tokens['colors'])} · fonts {len({f['pdf_name'] for f in tokens['fonts']})} · "
          f"sizes {len(tokens['font_sizes'])} · spacing {len(tokens['spacing'])}")


if __name__ == '__main__':
    main()
