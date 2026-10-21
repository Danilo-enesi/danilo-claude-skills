"""Pixel diff between a screenshot and a reference image (e.g. a section PNG from the PDF).

Usage: python diff.py <shot.png> <reference.png> [--ref-width 600] [--find | --crop x,y,w,h]
                      [--threshold 32] [--heatmap out.png]
--ref-width: px width the reference represents in the page (default: screenshot/crop width).
--find:      locate the reference inside the screenshot automatically (best match), then diff there.
--crop:      compare only this region of the screenshot (px).
--threshold: per-pixel channel difference (0-255) treated as equal (antialiasing noise).
Prints: diff %, compared area, position, heatmap path.
"""
import argparse, sys
from PIL import Image, ImageChops


def score(a, b):
    """Mean absolute difference of two same-size grayscale images (lower = more alike)."""
    h = ImageChops.difference(a, b).histogram()
    return sum(i * n for i, n in enumerate(h)) / (a.width * a.height)


def find(shot, ref, step=4):
    """Coarse search on a downscaled copy, then refine at full resolution around the best hit."""
    f = step
    s_small = shot.convert('L').resize((shot.width // f, shot.height // f))
    r_small = ref.convert('L').resize((max(ref.width // f, 1), max(ref.height // f, 1)))
    best = (float('inf'), 0, 0)
    for y in range(0, s_small.height - r_small.height + 1):
        for x in range(0, s_small.width - r_small.width + 1):
            d = score(s_small.crop((x, y, x + r_small.width, y + r_small.height)), r_small)
            if d < best[0]:
                best = (d, x * f, y * f)
    sg, rg = shot.convert('L'), ref.convert('L')
    _, bx, by = best
    best = (float('inf'), bx, by)
    for y in range(max(by - f, 0), min(by + f, shot.height - ref.height) + 1):
        for x in range(max(bx - f, 0), min(bx + f, shot.width - ref.width) + 1):
            d = score(sg.crop((x, y, x + ref.width, y + ref.height)), rg)
            if d < best[0]:
                best = (d, x, y)
    return best[1], best[2]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('shot')
    ap.add_argument('ref')
    ap.add_argument('--ref-width', type=int)
    ap.add_argument('--find', action='store_true')
    ap.add_argument('--crop')
    ap.add_argument('--threshold', type=int, default=32)
    ap.add_argument('--heatmap')
    a = ap.parse_args()
    shot = Image.open(a.shot).convert('RGB')
    if a.crop:
        x, y, w, h = map(int, a.crop.split(','))
        shot = shot.crop((x, y, x + w, y + h))
    ref = Image.open(a.ref).convert('RGB')
    rw = a.ref_width or shot.width
    ref = ref.resize((rw, round(ref.height * rw / ref.width)), Image.LANCZOS)
    pos = (0, 0)
    if a.find:
        if ref.width > shot.width or ref.height > shot.height:
            sys.exit('reference bigger than screenshot: check --ref-width')
        pos = find(shot, ref)
    x, y = pos
    h = min(ref.height, shot.height - y)
    w = min(ref.width, shot.width - x)
    s = shot.crop((x, y, x + w, y + h))
    r = ref.crop((0, 0, w, h))
    diff = ImageChops.difference(s, r).convert('L').point(lambda v: 255 if v > a.threshold else 0)
    pct = diff.histogram()[255] / (w * h) * 100
    if a.heatmap:
        Image.composite(Image.new('RGB', s.size, (255, 0, 0)), s.convert('L').convert('RGB'), diff).save(a.heatmap)
    note = '' if h == ref.height else f' (screenshot shorter than reference: {h} of {ref.height}px compared)'
    print(f'diff {pct:.2f}%  area {w}x{h} at {x},{y}{note}' + (f'  heatmap {a.heatmap}' if a.heatmap else ''))


if __name__ == '__main__':
    main()
