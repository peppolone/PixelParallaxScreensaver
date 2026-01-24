#!/usr/bin/env python3
"""
Estrae i frame di Guybrush con coordinate specifiche.
"""
from PIL import Image
from pathlib import Path

def detect_bg(img):
    p = img.convert('RGB').load()
    return p[0,0]

def remove_bg(img, bg, tol=15):
    img = img.convert('RGBA')
    p = img.load()
    for y in range(img.height):
        for x in range(img.width):
            r,g,b,a = p[x,y]
            if abs(r-bg[0])<=tol and abs(g-bg[1])<=tol and abs(b-bg[2])<=tol:
                p[x,y] = (0,0,0,0)
    return img

# Guybrush - frame camminata di profilo (riga Y=60)
# X = 30, 60, 90, 120, 150, 180
img = Image.open('GuybrushPart1.png')
bg = detect_bg(img)
print(f'Sfondo: {bg}')

# Frame: (x, y, width, height)
# Aumentata altezza da 45 a 55 per includere i piedi
frames = [
    (30, 60, 25, 55),
    (60, 60, 25, 55),
    (90, 60, 25, 55),
    (120, 60, 25, 55),
    (150, 60, 25, 55),
    (180, 60, 25, 55),
]

out_dir = Path('PixelParallax/Assets')
for i, (x, y, w, h) in enumerate(frames, 1):
    frame = img.crop((x, y, x+w, y+h))
    frame = remove_bg(frame, bg)
    out = out_dir / f'guybrush_walk_{i}.png'
    frame.save(out, 'PNG')
    print(f'Salvato: guybrush_walk_{i}.png')

print('Done!')
