#!/usr/bin/env python3
"""WCAG contrast ratio of two colours. Usage: contrast.py <hex text> <hex background>  ->  4.54:1"""
import sys
def lum(h):
    h = h.lstrip('#'); h = ''.join(c * 2 for c in h) if len(h) == 3 else h
    c = [int(h[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    c = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
a, b = sorted((lum(sys.argv[1]), lum(sys.argv[2])), reverse=True)
print(f"{(a + 0.05) / (b + 0.05):.2f}:1")
