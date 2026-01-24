#!/usr/bin/env python3
"""
Script generico per estrarre frame di animazione da sprite sheets Monkey Island.
Rimuove lo sfondo blu (#0000AA) e salva i frame come PNG trasparenti.

Uso:
    python3 extract_sprites.py <sprite_sheet.png> <nome_personaggio>

Esempi:
    python3 extract_sprites.py GuybrushPart1.png guybrush
    python3 extract_sprites.py LeChuck.png lechuck
    python3 extract_sprites.py Murray.png murray

I frame verranno salvati in PixelParallax/Assets/ come:
    {nome}_walk_1.png, {nome}_walk_2.png, ...
"""

import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("Installo Pillow...")
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "Pillow"])
    from PIL import Image

# Colori di sfondo comuni nei sprite sheet (prova in ordine)
BACKGROUND_COLORS = [
    (0, 0, 170),      # #0000AA - Blu scuro Monkey Island
    (171, 0, 171),    # #AB00AB - Magenta
    (255, 0, 255),    # #FF00FF - Magenta brillante  
    (0, 0, 0),        # #000000 - Nero
    (255, 255, 255),  # #FFFFFF - Bianco
]
TOLERANCE = 15


def detect_background_color(image: Image.Image) -> tuple:
    """Rileva automaticamente il colore di sfondo (il colore più comune negli angoli)."""
    if image.mode != 'RGB' and image.mode != 'RGBA':
        image = image.convert('RGB')
    
    pixels = image.load()
    width, height = image.size
    
    # Campiona i colori dagli angoli
    corner_colors = [
        pixels[0, 0],
        pixels[width-1, 0],
        pixels[0, height-1],
        pixels[width-1, height-1],
    ]
    
    # Usa il colore più comune
    from collections import Counter
    # Converti in RGB se necessario
    rgb_colors = []
    for c in corner_colors:
        if len(c) == 4:  # RGBA
            rgb_colors.append(c[:3])
        else:
            rgb_colors.append(c)
    
    most_common = Counter(rgb_colors).most_common(1)[0][0]
    return most_common


def remove_background(image: Image.Image, bg_color: tuple, tolerance: int = 15) -> Image.Image:
    """Rimuove il colore di sfondo e lo rende trasparente."""
    if image.mode != 'RGBA':
        image = image.convert('RGBA')
    
    pixels = image.load()
    width, height = image.size
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            if (abs(r - bg_color[0]) <= tolerance and 
                abs(g - bg_color[1]) <= tolerance and 
                abs(b - bg_color[2]) <= tolerance):
                pixels[x, y] = (0, 0, 0, 0)
    
    return image


def auto_detect_frames(image: Image.Image, bg_color: tuple, tolerance: int = 15, row_height: int = 60) -> list:
    """Rileva automaticamente i frame nella prima riga dello sprite sheet."""
    if image.mode != 'RGBA':
        image = image.convert('RGBA')
    
    pixels = image.load()
    width, height = image.size
    
    frames = []
    in_frame = False
    frame_start = 0
    
    for x in range(width):
        has_content = False
        for y in range(min(row_height, height)):
            r, g, b, a = pixels[x, y]
            if not (abs(r - bg_color[0]) <= tolerance and 
                    abs(g - bg_color[1]) <= tolerance and 
                    abs(b - bg_color[2]) <= tolerance):
                has_content = True
                break
        
        if has_content and not in_frame:
            frame_start = x
            in_frame = True
        elif not has_content and in_frame:
            frame_width = x - frame_start
            if frame_width > 10:
                frames.append((frame_start, 4, frame_width, 52))
            in_frame = False
    
    return frames


def extract_frames(spritesheet_path: str, output_dir: str, character_name: str, max_frames: int = 8):
    """Estrae i frame di camminata dallo sprite sheet."""
    
    print(f"📂 Caricamento sprite sheet: {spritesheet_path}")
    img = Image.open(spritesheet_path)
    print(f"   Dimensioni: {img.size[0]}x{img.size[1]}")
    
    # Rileva automaticamente il colore di sfondo
    bg_color = detect_background_color(img)
    print(f"   Sfondo rilevato: RGB{bg_color}")
    
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    print("🔍 Rilevamento automatico dei frame...")
    frames = auto_detect_frames(img, bg_color)
    print(f"   Trovati {len(frames)} frame")
    
    extracted_count = 0
    for i, (x, y, w, h) in enumerate(frames[:max_frames], 1):
        try:
            frame = img.crop((x, y, x + w, y + h))
            frame = remove_background(frame, bg_color, TOLERANCE)
            
            output_file = output_path / f"{character_name}_walk_{i}.png"
            frame.save(output_file, "PNG")
            print(f"  ✓ Salvato: {output_file.name} ({w}x{h})")
            extracted_count += 1
            
        except Exception as e:
            print(f"  ✗ Errore frame {i}: {e}")
    
    return extracted_count


def main():
    script_dir = Path(__file__).parent
    output_dir = script_dir / "PixelParallax" / "Assets"
    
    if len(sys.argv) < 3:
        print(__doc__)
        print("\n🎮 Personaggi suggeriti per Monkey Island:")
        print("   - guybrush")
        print("   - lechuck")
        print("   - elaine")
        print("   - murray")
        print("   - stan")
        sys.exit(1)
    
    spritesheet_path = sys.argv[1]
    character_name = sys.argv[2].lower()
    
    if not Path(spritesheet_path).exists():
        print(f"❌ Errore: File non trovato: {spritesheet_path}")
        sys.exit(1)
    
    print(f"\n🎮 Estrazione sprite per: {character_name.upper()}")
    print("=" * 50)
    
    count = extract_frames(spritesheet_path, str(output_dir), character_name)
    
    if count > 0:
        print("\n" + "=" * 50)
        print("✅ ESTRAZIONE COMPLETATA!")
        print("=" * 50)
        print(f"\n📁 Frame salvati in: {output_dir}")
        print(f"   File: {character_name}_walk_1.png ... {character_name}_walk_{count}.png")
        print("\n📝 PROSSIMI PASSI:")
        print("   1. Esegui: ./install.sh")
        print("   2. Se il personaggio è nuovo, aggiungi il tipo in MICharacters.swift")
        print("=" * 50)
    else:
        print("\n❌ Nessun frame estratto. Verifica lo sprite sheet.")


if __name__ == "__main__":
    main()
