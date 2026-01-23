#!/usr/bin/env python3
"""
Script per creare sprite placeholder per il PixelParallax screensaver.
Puoi usare questi come template e modificarli in un editor grafico come:
- Aseprite (raccomandato, $20)
- Piskel (gratis, web): https://www.piskelapp.com
- Pixilart (gratis, web): https://www.pixilart.com
"""

import struct
import zlib
import os

def create_png(width, height, pixels, filename):
    """Crea un file PNG minimale dai dati pixel"""
    def make_chunk(chunk_type, data):
        chunk = chunk_type + data
        crc = zlib.crc32(chunk) & 0xffffffff
        return struct.pack('>I', len(data)) + chunk + struct.pack('>I', crc)
    
    signature = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    ihdr = make_chunk(b'IHDR', ihdr_data)
    
    raw_data = b''
    for y in range(height):
        raw_data += b'\x00'
        for x in range(width):
            idx = (y * width + x) * 4
            raw_data += bytes(pixels[idx:idx+4])
    
    compressed = zlib.compress(raw_data, 9)
    idat = make_chunk(b'IDAT', compressed)
    iend = make_chunk(b'IEND', b'')
    
    with open(filename, 'wb') as f:
        f.write(signature + ihdr + idat + iend)

# Colori RGBA
TRANSPARENT = [0, 0, 0, 0]
SKIN = [240, 208, 176, 255]
HAIR = [102, 64, 38, 255]
SHIRT_WHITE = [255, 255, 255, 255]
SHIRT_BLUE = [64, 128, 200, 255]
PANTS = [102, 64, 38, 255]
SHOES = [51, 32, 19, 255]
OUTLINE = [40, 30, 20, 255]
BANDANA = [220, 50, 50, 255]

def create_character_sprite(colors, filename):
    """Crea uno sprite personaggio 16x24"""
    width, height = 16, 24
    pixels = [TRANSPARENT] * (width * height)
    
    def set_pixel(x, y, color):
        if 0 <= x < width and 0 <= y < height:
            pixels[y * width + x] = color
    
    # Testa
    for x in range(6, 10):
        set_pixel(x, 3, colors['hair'])
        set_pixel(x, 4, colors['hair'])
    for x in range(5, 11):
        set_pixel(x, 5, SKIN)
        set_pixel(x, 6, SKIN)
        set_pixel(x, 7, SKIN)
    set_pixel(6, 6, OUTLINE)
    set_pixel(9, 6, OUTLINE)
    
    # Corpo
    for y in range(8, 14):
        for x in range(5, 11):
            set_pixel(x, y, colors['shirt'])
    
    # Braccia
    set_pixel(3, 9, SKIN)
    set_pixel(4, 10, SKIN)
    set_pixel(12, 9, SKIN)
    set_pixel(11, 10, SKIN)
    
    # Pantaloni
    for y in range(14, 18):
        for x in range(5, 8):
            set_pixel(x, y, PANTS)
        for x in range(8, 11):
            set_pixel(x, y, PANTS)
    
    # Piedi
    for x in range(4, 8):
        set_pixel(x, 18, SHOES)
        set_pixel(x, 19, SHOES)
    for x in range(8, 12):
        set_pixel(x, 18, SHOES)
        set_pixel(x, 19, SHOES)
    
    flat_pixels = []
    for c in pixels:
        flat_pixels.extend(c)
    create_png(width, height, flat_pixels, filename)

def main():
    output_dir = "PixelParallax/Assets"
    os.makedirs(output_dir, exist_ok=True)
    
    # Personaggio 1 - Guybrush (camicia bianca)
    create_character_sprite(
        {'hair': HAIR, 'shirt': SHIRT_WHITE},
        f"{output_dir}/character_walk_1.png"
    )
    print(f"Creato: {output_dir}/character_walk_1.png")
    
    # Personaggio 2 - Pirata (camicia blu)
    create_character_sprite(
        {'hair': [30, 30, 30, 255], 'shirt': SHIRT_BLUE},
        f"{output_dir}/character_walk_2.png"
    )
    print(f"Creato: {output_dir}/character_walk_2.png")
    
    # Personaggio 3 - Pirata con bandana
    create_character_sprite(
        {'hair': BANDANA, 'shirt': [200, 180, 150, 255]},
        f"{output_dir}/character_walk_3.png"
    )
    print(f"Creato: {output_dir}/character_walk_3.png")
    
    print("\n✅ Sprite placeholder creati!")
    print("\n📝 Per modificarli:")
    print("   1. Apri i file PNG in Aseprite, Piskel, o altro editor")
    print("   2. Modifica i pixel come vuoi")
    print("   3. Salva come PNG (mantieni la trasparenza)")
    print("   4. In Xcode: trascina i file nel progetto")
    print("   5. Seleziona 'Copy items if needed' e aggiungi al target")

if __name__ == "__main__":
    main()
