---
name: macos-screensaver
description: >
  Expert guidance for developing native macOS screensavers using Swift, ScreenSaver framework, 
  and Core Graphics. Use when: (1) Building screensavers for macOS, (2) Working with ScreenSaverView 
  subclasses, (3) Implementing animation loops with CVDisplayLink or animateOneFrame, (4) Rendering 
  pixel art or procedural graphics with Core Graphics, (5) Managing bundle structure for .saver files,
  (6) Debugging screensaver installation and preview issues, (7) Optimizing 60fps render performance,
  (8) Implementing day/night cycles, weather effects, or parallax scrolling.
---

# macOS Screensaver Development

Comprehensive guidance for developing native macOS screensavers using Swift and Core Graphics.

## Quick Start

Create a screensaver by subclassing `ScreenSaverView`:

```swift
import ScreenSaver

@objc(YourScreensaverView) 
class YourScreensaverView: ScreenSaverView {
    
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        animationTimeInterval = 1.0 / 60.0  // 60 FPS
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func animateOneFrame() {
        setNeedsDisplay(bounds)
    }
    
    override func draw(_ rect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        // Draw here using Core Graphics
    }
}
```

## Bundle Structure

A .saver bundle must follow this structure:

```
YourScreensaver.saver/
├── Contents/
│   ├── Info.plist
│   ├── MacOS/
│   │   └── YourScreensaver  (compiled binary)
│   └── Resources/
│       └── (optional assets)
```

### Critical Info.plist Keys

```xml
<key>NSPrincipalClass</key>
<string>YourScreensaver.YourScreensaverView</string>
<key>CFBundleIdentifier</key>
<string>com.yourcompany.YourScreensaver</string>
```

## Rendering Approaches

### Layer-Backed Rendering (Recommended)

Best performance for complex scenes:

```swift
private var drawingLayer: CALayer!

private func setupLayer() {
    wantsLayer = true
    drawingLayer = CALayer()
    drawingLayer.frame = bounds
    drawingLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
    layer = drawingLayer
}

override var wantsUpdateLayer: Bool { true }

override func animateOneFrame() {
    guard let context = createOffscreenContext() else { return }
    renderScene(context: context)
    
    if let image = context.makeImage() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        drawingLayer?.contents = image
        CATransaction.commit()
    }
}
```

### Create Offscreen Context

```swift
private func createOffscreenContext() -> CGContext? {
    let width = Int(bounds.width)
    let height = Int(bounds.height)
    guard width > 0 && height > 0 else { return nil }
    
    return CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | 
                    CGBitmapInfo.byteOrder32Little.rawValue
    )
}
```

## Pixel Art Rendering

Disable anti-aliasing for crisp pixels:

```swift
context.setShouldAntialias(false)
context.interpolationQuality = .none

let pixelSize: CGFloat = 3.0
context.setFillColor(color.cgColor)
context.fill(CGRect(x: x * pixelSize, y: y * pixelSize, 
                    width: pixelSize, height: pixelSize))
```

## Animation Patterns

### Time-Based Animation

```swift
private var lastTime: TimeInterval = 0

override func animateOneFrame() {
    let currentTime = CACurrentMediaTime()
    let deltaTime = lastTime > 0 ? CGFloat(currentTime - lastTime) : 0.016
    lastTime = currentTime
    
    position += velocity * deltaTime  // Smooth regardless of frame rate
}
```

### Day/Night Cycle

```swift
private var cycleTime: CGFloat = 0
private let cycleDuration: TimeInterval = 60.0

func updateCycle(deltaTime: CGFloat) {
    cycleTime += deltaTime / CGFloat(cycleDuration)
    if cycleTime > 1.0 { cycleTime = 0.0 }
    
    // Interpolate between environments
    if cycleTime < 0.25 {
        return lerpEnvironment(night, day, cycleTime * 4)
    } else if cycleTime < 0.75 {
        return day
    } else {
        return lerpEnvironment(day, night, (cycleTime - 0.75) * 4)
    }
}
```

### Parallax Scrolling

```swift
struct ParallaxLayer {
    var offset: CGFloat = 0
    let speed: CGFloat
    let drawFunc: (CGContext, CGFloat) -> Void
}

private var layers: [ParallaxLayer] = [
    ParallaxLayer(speed: 0.1) { ctx, offset in /* far mountains */ },
    ParallaxLayer(speed: 0.3) { ctx, offset in /* clouds */ },
    ParallaxLayer(speed: 0.5) { ctx, offset in /* sea */ },
    ParallaxLayer(speed: 1.0) { ctx, offset in /* foreground */ },
]

func update(deltaTime: CGFloat) {
    for i in 0..<layers.count {
        layers[i].offset += layers[i].speed * deltaTime * 50
    }
}
```

## Performance Optimization

1. **Avoid allocations in render loop** - Pre-allocate arrays
2. **Cache gradients and colors** - Create once, reuse
3. **Use dirty rects when possible** - Only redraw changed areas
4. **Batch similar draw calls** - Minimize state changes
5. **Profile with Instruments** - Time Profiler for bottlenecks

## Concurrency Best Practices

Mark rendering classes with `@MainActor`:

```swift
@MainActor
class MyRenderer {
    private var particles: [Particle] = []
    
    func update(deltaTime: CGFloat) { /* Safe on main thread */ }
    func draw(context: CGContext) { /* Safe on main thread */ }
}
```

Use actors for thread-safe caching:

```swift
actor SpriteCache {
    private var cache: [String: CGImage] = [:]
    
    func load(named: String) -> CGImage? {
        if let cached = cache[named] { return cached }
        // Load and cache...
    }
}
```

## Installation

```bash
# User installation
cp -R YourScreensaver.saver ~/Library/Screen\ Savers/

# System-wide (requires admin)
sudo cp -R YourScreensaver.saver /Library/Screen\ Savers/
```

## Build Command

```bash
swiftc -emit-library -target arm64-apple-macosx14.0 \
  -framework ScreenSaver -framework Cocoa -framework AppKit \
  -o YourScreensaver.saver/Contents/MacOS/YourScreensaver \
  Sources/*.swift
```

## Debugging

View screensaver logs:

```bash
log stream --predicate 'subsystem == "com.apple.ScreenSaver"' --level debug
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Not appearing in System Settings | Check `NSPrincipalClass` matches `ModuleName.ClassName` |
| Crashes on preview | Handle all optionals in init, check isPreview |
| Black screen | Verify draw()/animateOneFrame() renders content |
| Slow/stuttering | Use layer-backed rendering, reduce allocations |
| Wrong colors on preview | Preview may use different color space |
