#!/usr/bin/env python3
"""Render ANSI-colored terminal text (tmux capture-pane -e) to PNG. usage: ansi2png.py out.png < in.txt"""
import re, sys
from PIL import Image, ImageDraw, ImageFont

FONT = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf'
S = 2                                   # supersample for crisp text
FS, CH, PAD = 13 * S, 18 * S, 14 * S
BG, FG = '#1e1e1e', '#d4d4d4'
BASE = ['#2e3436','#cc0000','#4e9a06','#c4a000','#3465a4','#75507b','#06989a','#d3d7cf',
        '#555753','#ef2929','#8ae234','#fce94f','#729fcf','#ad7fa8','#34e2e2','#eeeeec']

def c256(n):
    if n < 16: return BASE[n]
    if n < 232:
        n -= 16; r, g, b = n // 36, (n // 6) % 6, n % 6
        return '#%02x%02x%02x' % tuple(0 if v == 0 else 55 + 40 * v for v in (r, g, b))
    v = 8 + 10 * (n - 232); return '#%02x%02x%02x' % (v, v, v)

def parse(line):
    fg = bg = None; bold = rev = False; out = []
    for tok in re.split(r'(\x1b\[[0-9;]*m)', line):
        if tok.startswith('\x1b['):
            p = [int(x or 0) for x in tok[2:-1].split(';')] or [0]; i = 0
            while i < len(p):
                v = p[i]
                if v == 0: fg = bg = None; bold = rev = False
                elif v == 1: bold = True
                elif v == 22: bold = False
                elif v == 7: rev = True
                elif v == 27: rev = False
                elif v == 39: fg = None
                elif v == 49: bg = None
                elif 30 <= v <= 37: fg = BASE[v - 30]
                elif 90 <= v <= 97: fg = BASE[v - 90 + 8]
                elif 40 <= v <= 47: bg = BASE[v - 40]
                elif 100 <= v <= 107: bg = BASE[v - 100 + 8]
                elif v in (38, 48) and i + 2 < len(p) and p[i + 1] == 5:
                    col = c256(p[i + 2]); i += 2
                    if v == 38: fg = col
                    else: bg = col
                elif v in (38, 48) and i + 4 < len(p) and p[i + 1] == 2:
                    col = '#%02x%02x%02x' % (p[i + 2], p[i + 3], p[i + 4]); i += 4
                    if v == 38: fg = col
                    else: bg = col
                i += 1
        elif tok:
            f, b = (bg or BG, fg or FG) if rev else (fg or FG, bg)
            out.append((tok, f, b, bold))
    return out

lines = sys.stdin.read().split('\n')
while lines and not lines[-1].strip(): lines.pop()
rows = [parse(l) for l in lines]
font = ImageFont.truetype(FONT, FS); bfont = ImageFont.truetype(FONT.replace('.ttf', '-Bold.ttf'), FS)
CW = font.getlength('M')
width = max((sum(len(t) for t, *_ in r) for r in rows), default=80)
img = Image.new('RGB', (int(width * CW + 2 * PAD), int(len(rows) * CH + 2 * PAD)), BG)
d = ImageDraw.Draw(img)
for y, r in enumerate(rows):
    x = 0.0
    for text, fg, bg, bold in r:
        w = len(text) * CW
        if bg: d.rectangle([PAD + x, PAD + y * CH, PAD + x + w, PAD + (y + 1) * CH], fill=bg)
        d.text((PAD + x, PAD + y * CH + 2 * S), text, font=bfont if bold else font, fill=fg)
        x += w
img = img.resize((img.width // S, img.height // S), Image.LANCZOS)
img.save(sys.argv[1], optimize=True)
