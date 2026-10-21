"""Convert SVG files to PNG (transparent background) and optionally a dark-mode variant.

Usage: python svg2png.py <file.svg|folder> [...] [--out folder] [--scale 2] [--width 48] [--dark]
--scale: multiplier over the SVG's own size (2 = retina). --width overrides it with an exact px width.
--dark:  also writes <name>.dark.png: every color gets its lightness inverted (hue and saturation
         kept), so black<->white flip and brand mid-tones barely move.
Prints one line per written file.
"""
import argparse, colorsys, glob, os, re, sys
import pymupdf

NAMED = {'black': '#000000', 'white': '#ffffff', 'gray': '#808080', 'grey': '#808080',
         'red': '#ff0000', 'green': '#008000', 'blue': '#0000ff'}
COLOR = re.compile(r'#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b|rgb\(\s*\d+\s*,\s*\d+\s*,\s*\d+\s*\)|'
                   r'(?<=["\':\s])(?:' + '|'.join(NAMED) + r')(?=["\';\s])')


def to_rgb(c):
    c = NAMED.get(c.lower(), c)
    if c.startswith('rgb'):
        return [int(v) / 255 for v in re.findall(r'\d+', c)]
    c = c.lstrip('#')
    if len(c) == 3:
        c = ''.join(ch * 2 for ch in c)
    return [int(c[i:i + 2], 16) / 255 for i in (0, 2, 4)]


def invert_lightness(c):
    h, l, s = colorsys.rgb_to_hls(*to_rgb(c))
    r, g, b = colorsys.hls_to_rgb(h, 1 - l, s)
    return '#%02x%02x%02x' % (round(r * 255), round(g * 255), round(b * 255))


def dark_svg(text):
    text = COLOR.sub(lambda m: invert_lightness(m.group(0)), text)
    # unpainted shapes default to black fill and currentColor: make that default white on dark
    def root(m):
        tag = m.group(0)
        if not re.search(r'\sfill\s*=', tag):
            tag = tag[:-1] + ' fill="#ffffff">'
        if not re.search(r'\scolor\s*=', tag):
            tag = tag[:-1] + ' color="#ffffff">'
        return tag
    return re.sub(r'<svg\b[^>]*>', root, text, count=1)


def render(svg_text, path, scale, width):
    doc = pymupdf.open(stream=svg_text.encode('utf-8'), filetype='svg')
    page = doc[0]
    z = width / page.rect.width if width else scale
    page.get_pixmap(matrix=pymupdf.Matrix(z, z), alpha=True).save(path)
    return round(page.rect.width * z), round(page.rect.height * z)


def main():
    sys.stdout.reconfigure(encoding='utf-8')
    ap = argparse.ArgumentParser()
    ap.add_argument('inputs', nargs='+')
    ap.add_argument('--out')
    ap.add_argument('--scale', type=float, default=2)
    ap.add_argument('--width', type=int)
    ap.add_argument('--dark', action='store_true')
    a = ap.parse_args()
    files = [f for i in a.inputs for f in (sorted(glob.glob(os.path.join(i, '*.svg'))) if os.path.isdir(i) else [i])]
    for f in files:
        out_dir = a.out or os.path.dirname(f) or '.'
        os.makedirs(out_dir, exist_ok=True)
        base = os.path.join(out_dir, os.path.splitext(os.path.basename(f))[0])
        text = open(f, encoding='utf-8').read()
        try:
            w, h = render(text, base + '.png', a.scale, a.width)
            print(f'{base}.png  {w}x{h}')
            if a.dark:
                render(dark_svg(text), base + '.dark.png', a.scale, a.width)
                print(f'{base}.dark.png  {w}x{h}')
        except Exception as e:
            print(f'FAILED {f}: {e}')
    print(f'{len(files)} svg processed')


if __name__ == '__main__':
    main()
