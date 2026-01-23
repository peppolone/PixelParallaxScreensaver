# GitHub Copilot Instructions for PixelParallaxScreensaver

## Project Overview
This is a native macOS screensaver written in Swift using Core Graphics only (no SceneKit/SpriteKit).
The screensaver displays a side-scrolling pixel-art beach scene with dynamic day/night cycles, weather effects, and animated NPCs.

## Tech Stack
- **Language**: Swift 5.9+
- **Platform**: macOS 14.0+ (Sonoma)
- **Frameworks**: ScreenSaver, AppKit, Cocoa, Core Graphics
- **Build System**: Swift Package Manager / Xcode
- **Architecture**: Apple Silicon (arm64) and Intel (x86_64)

## Project Structure
- `PixelParallax/` - Main source code
  - `PixelParallaxView.swift` - Entry point, display link loop, main coordinator
  - `MIPalette.swift` - Color palette engine for time-of-day transitions
  - `MIBackground.swift` - Sky gradients, stars, celestial rendering
  - `MIScenery.swift` - Palm trees, ships, bonfire, particle effects
  - `MICharacters.swift` - NPC management, movement, sprite animation
  - `MISpriteLoader.swift` - Sprite loading and caching utilities
  - `Assets/` - PNG sprite sheets for character animations

## Coding Guidelines

### Swift Style
- Use Swift 5.9+ features where appropriate
- Prefer `let` over `var` when possible
- Use meaningful variable names that describe purpose
- Keep functions focused and small (< 30 lines ideally)
- Use guard statements for early returns

### Core Graphics Patterns
- All rendering happens in `draw(_:)` methods
- Use `CGContext` for all drawing operations
- Colors are defined in `MIPalette` and accessed via palette engine
- Coordinates use CGFloat and CGPoint/CGRect

### Performance Considerations
- Avoid allocations in the render loop
- Cache computed values when possible
- Use dirty-rect updates rather than full redraws
- Keep the 60fps target in mind

### Animation System
- Display link drives updates at 60fps
- Time-based animation (deltaTime) for smooth movement
- State machines for character behaviors
- Parallax layers update at different speeds

## Common Tasks

### Adding a New Character
1. Add sprite assets to `PixelParallax/Assets/`
2. Update `MICharacters.swift` with new character type
3. Define animation frames and timing
4. Add spawn logic in the character manager

### Adding a New Weather Effect
1. Create particle system in `MIScenery.swift`
2. Define particle properties (count, velocity, color)
3. Add weather state transition logic
4. Update palette for weather-specific colors

### Modifying Day/Night Cycle
1. Edit time thresholds in `MIPalette.swift`
2. Adjust color gradients for each phase
3. Update star visibility logic in `MIBackground.swift`

## Testing
- Build with Xcode or `swiftc` command line
- Install to `~/Library/Screen Savers/`
- Preview in System Settings → Screen Saver
- Use Console.app to view debug logs

## Build Commands
```bash
# Compile
swiftc -emit-library -target arm64-apple-macosx14.0 \
  -framework ScreenSaver -framework Cocoa -framework AppKit \
  -o PixelParallax.saver/Contents/MacOS/PixelParallax \
  PixelParallax/*.swift

# Install
cp -R PixelParallax.saver ~/Library/Screen\ Savers/
```

## Important Notes
- This is a ScreenSaver bundle, not a regular app
- The main class must inherit from `ScreenSaverView`
- Info.plist must declare the principal class correctly
- No external dependencies - pure Swift and system frameworks
