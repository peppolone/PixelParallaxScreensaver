# PixelParallax Screensaver

A native macOS Screensaver written in Swift (No SceneKit/SpriteKit) using pure Core Graphics.
Implements a side-scrolling pixel-art beach scene with dynamic day/night cycles, weather, and NPCs.

## Features

- **Procedural Pixel Art**: Almost all graphics (trees, ship, bonfire, characters) are drawn via code (Core Graphics).
- **Dynamic Lighting**: Sky gradients change from Night -> Sunrise -> Day -> Sunset using a custom palette engine (`MIPalette`).
- **Weather System**: Random rain storms with wind physics.
- **NPCs**: Includes pixel-art characters (inspired by Monkey Island) walking along the beach with simple animation cycles.
- **Parallax Scrolling**: multiple layers (Background, Ships, Waves, Beach, Foreground Palms).

## Installation

### Automatic
Run the included install script:
```bash
./install.sh
```
This will compile the screensaver and install it to your `~/Library/Screen Savers` folder.

### Manual
1. Compile the code:
   ```bash
   swiftc -emit-library -target arm64-apple-macosx14.0 \
     -framework ScreenSaver -framework Cocoa -framework AppKit \
     -o PixelParallax.saver/Contents/MacOS/PixelParallax \
     PixelParallax/*.swift
   ```
2. Move `PixelParallax.saver` to `~/Library/Screen Savers`.

## Architecture

- **PixelParallaxView.swift**: Main entry point. Handles the display link loop and coordinates updates.
- **MIPalette.swift**: Defines color schemes for different times of day.
- **MIScenery.swift**: Handles static environment (Palms) and dynamic elements (Bonfire particles).
- **MICharacters.swift**: Manages NPC instantiation, movement, and pixel-sprite rendering.
- **MIBackground.swift**: Handles star fields and sky gradients.

## Optimization Notes
- Uses `draw(_:)` with `setNeedsDisplay` driven by `CVDisplayLink` (via `ScreenSaverView`'s internal timer adaptation) for smooth 60fps.
- Low memory footprint as no external image assets are loaded.

## License
MIT
