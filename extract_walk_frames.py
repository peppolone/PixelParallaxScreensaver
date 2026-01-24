#!/usr/bin/env python3
"""
Script per estrarre MANUALMENTE i frame di camminata laterale.
Permette di specificare le coordinate esatte dei frame da estrarre.

Uso:
    python3 extract_walk_frames.py

Lo script mostrerà una griglia sull'immagine per aiutare a identificare le coordinate.
"""

import sys
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Installo Pillow...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image, ImageDraw, ImageFont


def detect_background_color(image: Image.Image) -> tuple:
    """Rileva il colore di sfondo dagli angoli."""
    if image.mode != 'RGB' and image.mode != 'RGBA':
        image = image.convert('RGB')
    pixels = image.load()
    w, h = image.size
    corners = [pixels[0,0], pixels[w-1,0], pixels[0,h-1], pixels[w-1,h-1]]
    from collections import Counter
    rgb = [c[:3] if len(c)==4 else c for c in corners]
    return Counter(rgb).most_common(1)[0][0]


def remove_background(image: Image.Image, bg_color: tuple, tolerance: int = 15) -> Image.Image:
    """Rimuove il colore di sfondo."""
    if image.mode != 'RGBA':
        image = image.convert('RGBA')
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r, g, b, a = pixels[x, y]
            if (abs(r - bg_color[0]) <= tolerance and 
                abs(g - bg_color[1]) <= tolerance and 
                abs(b - bg_color[2]) <= tolerance):
                pixels[x, y] = (0, 0, 0, 0)
    return image


def create_grid_image(spritesheet_path: str, grid_size: int = 50):
    """Crea un'immagine con griglia per aiutare a identificare le coordinate."""
    img = Image.open(spritesheet_path)
    if img.mode != 'RGB':
        img = img.convert('RGB')
    
    draw = ImageDraw.Draw(img)
    w, h = img.size
    
    # Disegna griglia
    for x in range(0, w, grid_size):
        draw.line([(x, 0), (x, h)], fill=(255, 0, 0), width=1)
        draw.text((x+2, 2), str(x), fill=(255, 255, 0))
    
    for y in range(0, h, grid_size):
        draw.line([(0, y), (w, y)], fill=(255, 0, 0), width=1)
        draw.text((2, y+2), str(y), fill=(255, 255, 0))
    
    output = spritesheet_path.replace('.png', '_grid.png')
    img.save(output)
    print(f"Griglia salvata: {output}")
    return output


def extract_specific_frames(spritesheet_path: str, character_name: str, frame_coords: list, output_dir: str):
    """Estrae frame specifici dalle coordinate fornite."""
    img = Image.open(spritesheet_path)
    bg_color = detect_background_color(img)
    print(f"Sfondo: RGB{bg_color}")
    
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    for i, (x, y, w, h) in enumerate(frame_coords, 1):
        frame = img.crop((x, y, x + w, y + h))
        frame = remove_background(frame, bg_color)
        
        output_file = output_path / f"{character_name}_walk_{i}.png"
        frame.save(output_file, "PNG")
        print(f"  ✓ {output_file.name} ({w}x{h})")


# Coordinate manuali per i frame di camminata laterale
# Formato: (x, y, width, height)
# Questi valori devono essere verificati visivamente!

WALK_FRAMES = {
    # Guybrush - camminata di profilo (prima riga, primi 6 frame)
    'guybrush': [
        (4, 8, 24, 45),     # Frame 1
        (32, 8, 24, 45),    # Frame 2
        (60, 8, 24, 45),    # Frame 3
        (88, 8, 24, 45),    # Frame 4
        (116, 8, 24, 45),   # Frame 5
        (144, 8, 24, 45),   # Frame 6
    ],
    
    # LeChuck - da determinare guardando l'immagine con griglia
    'lechuck': [
        # Placeholder - da aggiornare con coordinate reali
        (10, 10, 40, 60),
        (60, 10, 40, 60),
        (110, 10, 40, 60),
        (160, 10, 40, 60),
    ],
    
    # Elaine - da determinare guardando l'immagine con griglia  
    'elaine': [
        # Placeholder - da aggiornare con coordinate reali
        (10, 10, 25, 50),
        (40, 10, 25, 50),
        (70, 10, 25, 50),
        (100, 10, 25, 50),
    ],
    
    # Carla - da determinare guardando l'immagine con griglia
    'carla': [
        # Placeholder - da aggiornare con coordinate reali
        (10, 10, 25, 50),
        (40, 10, 25, 50),
        (70, 10, 25, 50),
        (100, 10, 25, 50),
    ],
}


def main():
    script_dir = Path(__file__).parent
    output_dir = script_dir / "PixelParallax" / "Assets"
    
    print("=" * 60)
    print("ESTRAZIONE MANUALE FRAME DI CAMMINATA")
    print("=" * 60)
    
    spritesheets = {
        'guybrush': 'GuybrushPart1.png',
        'lechuck': 'Lechuck.png', 
        'elaine': 'TSOMI_Elaine.png',
        'carla': 'MICarlaSheet.png',
    }
    
    print("\nComandi disponibili:")
    print("  1. Crea immagini con griglia (per trovare coordinate)")
    print("  2. Estrai frame con coordinate attuali")
    print("  3. Esci")
    
    choice = input("\nScelta: ").strip()
    
    if choice == '1':
        print("\nCreazione griglie...")
        for name, path in spritesheets.items():
            if Path(path).exists():
                create_grid_image(path)
            else:
                print(f"  ✗ {path} non trovato")
        print("\nApri le immagini *_grid.png per vedere le coordinate!")
        print("Poi modifica WALK_FRAMES in questo script con le coordinate corrette.")
        
    elif choice == '2':
        print("\nEstrazione frame...")
        for name, path in spritesheets.items():
            if Path(path).exists() and name in WALK_FRAMES:
                print(f"\n{name.upper()}:")
                extract_specific_frames(path, name, WALK_FRAMES[name], str(output_dir))
        print("\n✅ Fatto! Esegui ./install.sh per installare")
        
    else:
        print("Uscita.")


if __name__ == "__main__":
    main()
