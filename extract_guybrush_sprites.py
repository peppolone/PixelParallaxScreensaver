#!/usr/bin/env python3
"""
Script per estrarre i frame di camminata di Guybrush dallo sprite sheet.
Rimuove lo sfondo blu (#0000AA) e salva i frame come PNG trasparenti.

Uso:
    python3 extract_guybrush_sprites.py guybrush_spritesheet.png

I frame verranno salvati in PixelParallax/Assets/ come:
    guybrush_walk_1.png, guybrush_walk_2.png, ...
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

# Colore di sfondo da rendere trasparente (blu scuro Monkey Island)
BACKGROUND_COLOR = (0, 0, 170)  # #0000AA

# Coordinate dei frame di camminata (x, y, width, height)
# Questi sono i frame della prima riga dello sprite sheet
# La camminata è composta da 6 frame principali
WALK_FRAMES = [
    # Riga 1: Walk cycle verso destra
    (4, 6, 24, 48),      # Frame 1
    (34, 6, 24, 48),     # Frame 2
    (64, 6, 24, 48),     # Frame 3
    (94, 6, 24, 48),     # Frame 4
    (124, 6, 24, 48),    # Frame 5
    (154, 6, 24, 48),    # Frame 6
]

# Frame alternativi dalla seconda riga (camminata più fluida)
WALK_FRAMES_ALT = [
    (4, 60, 24, 48),     # Frame 1 alt
    (34, 60, 24, 48),    # Frame 2 alt
    (64, 60, 24, 48),    # Frame 3 alt
    (94, 60, 24, 48),    # Frame 4 alt
    (124, 60, 24, 48),   # Frame 5 alt
    (154, 60, 24, 48),   # Frame 6 alt
]


def remove_background(image: Image.Image, bg_color: tuple, tolerance: int = 15) -> Image.Image:
    """Rimuove il colore di sfondo e lo rende trasparente."""
    # Converti in RGBA se necessario
    if image.mode != 'RGBA':
        image = image.convert('RGBA')
    
    pixels = image.load()
    width, height = image.size
    
    for y in range(height):
        for x in range(width):
            r, g, b, a = pixels[x, y]
            
            # Controlla se il pixel è vicino al colore di sfondo
            if (abs(r - bg_color[0]) <= tolerance and 
                abs(g - bg_color[1]) <= tolerance and 
                abs(b - bg_color[2]) <= tolerance):
                pixels[x, y] = (0, 0, 0, 0)  # Trasparente
    
    return image


def auto_detect_frames(image: Image.Image, bg_color: tuple, tolerance: int = 15) -> list:
    """
    Rileva automaticamente i frame nella prima riga dello sprite sheet
    cercando i bounding box dei personaggi.
    """
    if image.mode != 'RGBA':
        image = image.convert('RGBA')
    
    pixels = image.load()
    width, height = image.size
    
    # Trova le colonne che contengono pixel non di sfondo nella prima riga (0-60 px)
    row_height = 60
    frames = []
    in_frame = False
    frame_start = 0
    
    for x in range(width):
        has_content = False
        for y in range(row_height):
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
            # Trovato un frame
            frame_width = x - frame_start
            if frame_width > 10:  # Ignora frame troppo piccoli
                frames.append((frame_start, 4, frame_width, 52))
            in_frame = False
    
    return frames


def extract_frames(spritesheet_path: str, output_dir: str, use_auto_detect: bool = True):
    """Estrae i frame di camminata dallo sprite sheet."""
    
    # Carica l'immagine
    print(f"Caricamento sprite sheet: {spritesheet_path}")
    img = Image.open(spritesheet_path)
    print(f"Dimensioni: {img.size[0]}x{img.size[1]}")
    
    # Crea la directory di output se non esiste
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Usa il rilevamento automatico o le coordinate manuali
    if use_auto_detect:
        print("Rilevamento automatico dei frame...")
        frames = auto_detect_frames(img, BACKGROUND_COLOR)
        if len(frames) < 4:
            print("Rilevamento automatico insufficiente, uso coordinate manuali")
            frames = WALK_FRAMES
    else:
        frames = WALK_FRAMES
    
    print(f"Trovati {len(frames)} frame di camminata")
    
    # Estrai ogni frame
    extracted_count = 0
    for i, (x, y, w, h) in enumerate(frames[:8], 1):  # Max 8 frame
        try:
            # Ritaglia il frame
            frame = img.crop((x, y, x + w, y + h))
            
            # Rimuovi lo sfondo
            frame = remove_background(frame, BACKGROUND_COLOR)
            
            # Salva il frame
            output_file = output_path / f"guybrush_walk_{i}.png"
            frame.save(output_file, "PNG")
            print(f"  ✓ Salvato: {output_file.name} ({w}x{h})")
            extracted_count += 1
            
        except Exception as e:
            print(f"  ✗ Errore frame {i}: {e}")
    
    print(f"\n✓ Estratti {extracted_count} frame in {output_dir}")
    return extracted_count


def interactive_mode(spritesheet_path: str):
    """Modalità interattiva per identificare i frame manualmente."""
    print("\n=== MODALITÀ INTERATTIVA ===")
    print("Apri l'immagine in un editor grafico e trova le coordinate.")
    print("Per ogni frame, inserisci: x,y,larghezza,altezza")
    print("Digita 'done' quando hai finito.\n")
    
    frames = []
    while True:
        try:
            user_input = input(f"Frame {len(frames)+1} (x,y,w,h) o 'done': ").strip()
            if user_input.lower() == 'done':
                break
            
            parts = [int(x.strip()) for x in user_input.split(',')]
            if len(parts) == 4:
                frames.append(tuple(parts))
                print(f"  Aggiunto frame: {parts}")
            else:
                print("  Formato non valido. Usa: x,y,larghezza,altezza")
        except ValueError:
            print("  Inserisci numeri validi separati da virgola")
        except KeyboardInterrupt:
            print("\nInterrotto.")
            break
    
    return frames


def main():
    # Directory di output
    script_dir = Path(__file__).parent
    output_dir = script_dir / "PixelParallax" / "Assets"
    
    # Controlla gli argomenti
    if len(sys.argv) < 2:
        # Cerca automaticamente file che potrebbero essere lo sprite sheet
        possible_files = list(script_dir.glob("*guybrush*.png")) + \
                         list(script_dir.glob("*sprite*.png")) + \
                         list(script_dir.glob("*monkey*.png"))
        
        if possible_files:
            print(f"Trovato possibile sprite sheet: {possible_files[0]}")
            spritesheet_path = str(possible_files[0])
        else:
            print("Uso: python3 extract_guybrush_sprites.py <sprite_sheet.png>")
            print("\nSalva lo sprite sheet di Guybrush nella cartella del progetto")
            print("e richiama questo script con il percorso del file.")
            print(f"\nEsempio:")
            print(f"  python3 extract_guybrush_sprites.py ~/Downloads/guybrush.png")
            sys.exit(1)
    else:
        spritesheet_path = sys.argv[1]
    
    # Verifica che il file esista
    if not Path(spritesheet_path).exists():
        print(f"Errore: File non trovato: {spritesheet_path}")
        sys.exit(1)
    
    # Estrai i frame
    try:
        count = extract_frames(spritesheet_path, str(output_dir), use_auto_detect=True)
        
        if count > 0:
            print("\n" + "="*50)
            print("PROSSIMI PASSI:")
            print("="*50)
            print("1. Apri il progetto in Xcode")
            print("2. Trascina i nuovi PNG nel progetto")
            print("3. Ricompila e testa lo screensaver")
            print("="*50)
        else:
            print("\nNessun frame estratto. Prova la modalità interattiva:")
            print(f"  python3 {__file__} --interactive {spritesheet_path}")
            
    except Exception as e:
        print(f"Errore durante l'estrazione: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
