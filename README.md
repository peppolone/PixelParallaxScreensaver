# 🏝️ PixelParallax Screensaver

<p align="center">
  <img src="https://img.shields.io/badge/Status-🚧%20Work%20in%20Progress-yellow?style=flat-square" alt="WIP">
  <img src="https://img.shields.io/badge/macOS-14.0+-blue?style=flat-square&logo=apple" alt="macOS">
  <img src="https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square&logo=swift" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License">
</p>

> ⚠️ **This project is under active development!** Features may change and some sprites are still being refined.

A **native macOS screensaver** written entirely in Swift using **pure Core Graphics** — no SceneKit, no SpriteKit, no external dependencies.

Experience a beautiful side-scrolling **pixel-art beach scene** inspired by classic adventure games like **The Secret of Monkey Island**, featuring dynamic day/night cycles, weather effects, and animated characters.

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🎨 **Procedural Pixel Art** | All graphics (trees, ships, bonfire, characters) are rendered via code using Core Graphics |
| 🌅 **Dynamic Day/Night Cycle** | Sky gradients smoothly transition: Night → Sunrise → Day → Sunset |
| 🌧️ **Weather System** | Random rain storms with realistic wind physics |
| 🚶 **Animated NPCs** | Pixel-art characters (Monkey Island inspired!) walking along the beach |
| 🏝️ **Parallax Scrolling** | Multiple layers create depth: Background, Ships, Waves, Beach, Foreground Palms |
| ⚡ **60fps Performance** | Optimized for smooth animation with minimal CPU/GPU usage |

---

## 📦 Installation

### Quick Install (Recommended)

```bash
git clone https://github.com/peppolone/PixelParallaxScreensaver.git
cd PixelParallaxScreensaver
./install.sh
```

The script will compile the screensaver and install it to `~/Library/Screen Savers`.

### Manual Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/peppolone/PixelParallaxScreensaver.git
   cd PixelParallaxScreensaver
   ```

2. **Compile the screensaver:**
   ```bash
   swiftc -emit-library -target arm64-apple-macosx14.0 \
     -framework ScreenSaver -framework Cocoa -framework AppKit \
     -o PixelParallax.saver/Contents/MacOS/PixelParallax \
     PixelParallax/*.swift
   ```

3. **Install:**
   ```bash
   cp -R PixelParallax.saver ~/Library/Screen\ Savers/
   ```

4. **Activate:**
   - Open **System Settings** → **Screen Saver**
   - Select **PixelParallax** from the list

---

## 🔧 Requirements

- **macOS 14.0** (Sonoma) or later
- **Apple Silicon** (M1/M2/M3) or Intel Mac
- **Xcode Command Line Tools** (for compilation)

To install Xcode Command Line Tools:
```bash
xcode-select --install
```

---

## 🏗️ Project Structure

```
PixelParallaxScreensaver/
├── PixelParallax/
│   ├── PixelParallaxView.swift   # Main entry point & display loop
│   ├── MIPalette.swift           # Color schemes for time of day
│   ├── MIBackground.swift        # Star fields & sky gradients
│   ├── MIScenery.swift           # Palms, bonfire & particles
│   ├── MICharacters.swift        # NPC movement & animation
│   ├── MISpriteLoader.swift      # Sprite loading utilities
│   └── Assets/                   # Character sprite PNGs
│       ├── guybrush_walk_*.png   # Guybrush walking frames (6)
│       ├── lechuck_walk_*.png    # LeChuck walking frames (8)
│       ├── elaine_walk_*.png     # Elaine walking frames (7)
│       └── carla_walk_*.png      # Carla walking frames (8)
├── PixelParallax.xcodeproj/      # Xcode project
├── install.sh                    # Installation script
└── README.md
```

---

## 🎮 How It Works

The screensaver uses a custom rendering pipeline:

1. **Display Link** drives the animation at 60fps
2. **MIPalette** calculates colors based on virtual time of day
3. **MIBackground** renders the sky gradient and stars
4. **MIScenery** draws palm trees, ships, and particle effects
5. **MICharacters** animates NPCs with simple state machines
6. All layers are composited with **parallax scrolling** for depth

### Performance Optimizations

- Direct Core Graphics rendering (no scene graph overhead)
- Minimal memory footprint (no large image assets)
- Efficient dirty-rect updates
- Hardware-accelerated compositing

---

## 🛠️ Development

### Building with Xcode

1. Open `PixelParallax.xcodeproj`
2. Select the **PixelParallax** scheme
3. Build (`⌘B`)

### Testing the Screensaver

After installation, you can preview it in System Settings or use:
```bash
open /System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane
```

---

## 🤝 Contributing

Contributions are welcome! Feel free to:

- 🐛 Report bugs
- 💡 Suggest new features
- 🎨 Add new character sprites
- 🌈 Create new color palettes

---

## 📝 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- Inspired by the art style of **Monkey Island** and classic LucasArts adventure games
- Built with ❤️ using pure Swift and Core Graphics

---

<p align="center">
  <i>Made with ☕ and nostalgia for pixel art</i>
</p>
