import Cocoa
import ScreenSaver

@objc(PixelParallaxView) class PixelParallaxView: ScreenSaverView {
    
    // MARK: - Constants
    private var pixelSize: CGFloat = 3.0  // Will be adjusted based on screen size
    private let dayDuration: TimeInterval = 60.0
    
    // MARK: - Modules
    private var background: MIBackground!
    private var scenery: MIScenery!
    private var characters: MICharacters!
    private var weather: MIWeather!
    
    // MARK: - State
    private var lastTime: TimeInterval = 0
    private var cycleTime: TimeInterval = 0.5
    private var frameCount: Int = 0
    private var isInPreview: Bool = false
    
    // MARK: - Layer-backed drawing
    private var drawingLayer: CALayer!
    
    // MARK: - Init
    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        self.isInPreview = isPreview
        
        // Adjust pixel size based on frame size for proper scaling
        // Full screen ~ 1920x1080, preview ~ 300x200
        // Scale proportionally
        let referenceWidth: CGFloat = 1920.0
        let scaleFactor = frame.width / referenceWidth
        pixelSize = max(1.0, 3.0 * scaleFactor)  // Minimum 1.0 pixel
        
        NSLog("PixelParallaxView INIT frame=\(frame) isPreview=\(isPreview) pixelSize=\(pixelSize)")
        initializeModules()
        setupLayer()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        // For coder init, calculate pixel size from current frame
        let referenceWidth: CGFloat = 1920.0
        let scaleFactor = frame.width / referenceWidth
        pixelSize = max(1.0, 3.0 * scaleFactor)
        initializeModules()
        setupLayer()
    }
    
    private func setupLayer() {
        // CRITICAL: Enable layer-backed rendering like Aerial screensaver
        wantsLayer = true
        
        // Create our drawing layer
        drawingLayer = CALayer()
        drawingLayer.frame = bounds
        drawingLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
        drawingLayer.backgroundColor = NSColor.red.cgColor // DEBUG: Red to confirm layer is visible
        layer = drawingLayer
        
        NSLog("PixelParallaxView setupLayer: wantsLayer=\(wantsLayer) layer=\(String(describing: layer))")
    }
    
    private func initializeModules() {
        animationTimeInterval = 1.0 / 30.0
        lastTime = CACurrentMediaTime()
        
        // Set the bundle for sprite loading BEFORE creating characters
        MISpriteLoader.shared.setBundle(from: self)
        
        background = MIBackground(pixelSize: pixelSize, bounds: bounds, isPreview: isInPreview)
        scenery = MIScenery(pixelSize: pixelSize, bounds: bounds, isPreview: isInPreview)
        characters = MICharacters(pixelSize: pixelSize, bounds: bounds, isPreview: isInPreview)
        weather = MIWeather(pixelSize: pixelSize, bounds: bounds, isPreview: isInPreview)
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func updateLayer() {
        // Called instead of draw() when wantsUpdateLayer is true
        // Skip for now - using animateOneFrame
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        NSLog("PixelParallaxView viewDidMoveToWindow window=\(String(describing: window))")
        if window != nil {
            drawingLayer?.frame = bounds
            startAnimation()
        }
    }
    
    // MARK: - Animation
    override func startAnimation() {
        super.startAnimation()
        NSLog("PixelParallaxView startAnimation isAnimating=\(isAnimating)")
    }
    
    override func stopAnimation() {
        super.stopAnimation()
        NSLog("PixelParallaxView stopAnimation")
    }
    
    override func animateOneFrame() {
        frameCount += 1
        let currentTime = CACurrentMediaTime()
        let deltaTime = lastTime > 0 ? CGFloat(currentTime - lastTime) : 0.033
        lastTime = currentTime
        
        // Update time cycle
        cycleTime += Double(deltaTime) / dayDuration
        if cycleTime > 1.0 { cycleTime = 0.0 }
        
        // Update modules
        background.update(deltaTime: deltaTime)
        scenery.update(deltaTime: deltaTime)
        characters.update(deltaTime: deltaTime, bounds: bounds)
        weather.update(deltaTime: TimeInterval(deltaTime))
        
        // TEST: Provo solo MIBackground.drawSky
        renderWithBackground()
        
        if frameCount % 30 == 0 {
            NSLog("PixelParallaxView animateOneFrame #\(frameCount)")
        }
    }
    
    private func renderWithBackground() {
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        
        guard width > 0 && height > 0 else { return }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            NSLog("PixelParallaxView: Failed to create CGContext!")
            return
        }
        
        // Pixel art settings
        context.setShouldAntialias(false)
        context.interpolationQuality = .none
        
        // Calculate environment
        let currentEnv = calculateEnvironment()
        
        // MIBackground
        background.drawSky(context: context, bounds: bounds, env: currentEnv)
        background.drawStars(context: context, bounds: bounds, env: currentEnv)
        background.drawCelestialBody(context: context, bounds: bounds, env: currentEnv)
        background.drawMountains(context: context, bounds: bounds, env: currentEnv)
        background.drawClouds(context: context, bounds: bounds, env: currentEnv)
        
        // MIScenery - test bonfire
        scenery.drawBeach(context: context, bounds: bounds, env: currentEnv)
        scenery.drawSea(context: context, bounds: bounds, env: currentEnv)
        scenery.drawShip(context: context, bounds: bounds, env: currentEnv)
        
        scenery.drawBonfire(context: context, bounds: bounds, env: currentEnv)
        characters.drawAll(context: context, bounds: bounds)
        scenery.drawPalms(context: context, bounds: bounds, env: currentEnv)
        scenery.drawFireflies(context: context, bounds: bounds, env: currentEnv)
        weather.draw(context: context, bounds: bounds, env: currentEnv)
        drawScanlines(context: context, bounds: bounds)
        drawVignette(context: context, bounds: bounds)
        
        // Crea immagine e assegna al layer
        if let image = context.makeImage() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            drawingLayer?.contents = image
            CATransaction.commit()
        }
    }
    
    private func renderSimpleGradient() {
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        
        guard width > 0 && height > 0 else { return }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            NSLog("PixelParallaxView: Failed to create CGContext!")
            return
        }
        
        // Disegna un gradiente cielo animato basato su cycleTime
        let topColor: CGColor
        let bottomColor: CGColor
        
        let t = CGFloat(cycleTime)
        if t < 0.3 {
            // Notte → alba
            topColor = NSColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0).cgColor
            bottomColor = NSColor(red: 0.2, green: 0.2, blue: 0.5, alpha: 1.0).cgColor
        } else if t < 0.7 {
            // Giorno
            topColor = NSColor(red: 0.4, green: 0.6, blue: 0.9, alpha: 1.0).cgColor
            bottomColor = NSColor(red: 0.7, green: 0.85, blue: 1.0, alpha: 1.0).cgColor
        } else {
            // Tramonto → notte
            topColor = NSColor(red: 0.8, green: 0.4, blue: 0.3, alpha: 1.0).cgColor
            bottomColor = NSColor(red: 0.9, green: 0.6, blue: 0.4, alpha: 1.0).cgColor
        }
        
        let gradient = CGGradient(colorsSpace: colorSpace, colors: [bottomColor, topColor] as CFArray, locations: [0, 1])!
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: CGFloat(height)), options: [])
        
        // Crea immagine e assegna al layer
        if let image = context.makeImage() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            drawingLayer?.contents = image
            CATransaction.commit()
        }
    }
    
    private func renderToLayerFull() {
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        
        guard width > 0 && height > 0 else { return }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            NSLog("PixelParallaxView: Failed to create CGContext!")
            return
        }
        
        // Pixel art settings
        context.setShouldAntialias(false)
        context.interpolationQuality = .none
        
        // Calculate environment
        let currentEnv = calculateEnvironment()
        
        // Draw all layers
        background.drawSky(context: context, bounds: bounds, env: currentEnv)
        background.drawStars(context: context, bounds: bounds, env: currentEnv)
        background.drawCelestialBody(context: context, bounds: bounds, env: currentEnv)
        background.drawMountains(context: context, bounds: bounds, env: currentEnv)
        background.drawClouds(context: context, bounds: bounds, env: currentEnv)
        
        scenery.drawBeach(context: context, bounds: bounds, env: currentEnv)
        scenery.drawSea(context: context, bounds: bounds, env: currentEnv)
        scenery.drawShip(context: context, bounds: bounds, env: currentEnv)
        
        scenery.drawBonfire(context: context, bounds: bounds, env: currentEnv)
        characters.drawAll(context: context, bounds: bounds)
        scenery.drawPalms(context: context, bounds: bounds, env: currentEnv)
        scenery.drawFireflies(context: context, bounds: bounds, env: currentEnv)
        weather.draw(context: context, bounds: bounds, env: currentEnv)
        drawScanlines(context: context, bounds: bounds)
        drawVignette(context: context, bounds: bounds)
        
        context.saveGState()
        characters.drawAll(context: context, bounds: bounds)
        context.restoreGState()
        
        scenery.drawFireflies(context: context, bounds: bounds, env: currentEnv)
        weather.draw(context: context, bounds: bounds, env: currentEnv)
        
        drawScanlines(context: context, bounds: bounds)
        drawVignette(context: context, bounds: bounds)
        
        // Set the layer contents
        if let image = context.makeImage() {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            drawingLayer?.contents = image
            CATransaction.commit()
        }
    }
    
    private func calculateEnvironment() -> MIPalette.Environment {
        let t = CGFloat(cycleTime)
        
        if t < 0.2 {
            return MIPalette.envNight
        } else if t < 0.3 {
            let progress = (t - 0.2) / 0.1
            return MIPalette.interpolate(from: MIPalette.envNight, to: MIPalette.envDay, t: progress)
        } else if t < 0.7 {
            return MIPalette.envDay
        } else if t < 0.8 {
            let progress = (t - 0.7) / 0.1
            return MIPalette.interpolate(from: MIPalette.envDay, to: MIPalette.envSunset, t: progress)
        } else if t < 0.9 {
            let progress = (t - 0.8) / 0.1
            return MIPalette.interpolate(from: MIPalette.envSunset, to: MIPalette.envNight, t: progress)
        } else {
            return MIPalette.envNight
        }
    }
    
    private func drawScanlines(context: CGContext, bounds: CGRect) {
        context.saveGState()
        context.setBlendMode(.overlay)
        context.setFillColor(NSColor.black.withAlphaComponent(0.15).cgColor)
        for y in stride(from: 0, through: bounds.height, by: 4) {
            context.fill(CGRect(x: 0, y: y, width: bounds.width, height: 2))
        }
        context.restoreGState()
    }
    
    private func drawVignette(context: CGContext, bounds: CGRect) {
        let gradientLocations: [CGFloat] = [0.0, 0.8, 1.0]
        let gradientColors = [
            NSColor.clear.cgColor,
            NSColor.black.withAlphaComponent(0.4).cgColor,
            NSColor.black.cgColor
        ] as CFArray
        
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: gradientColors, locations: gradientLocations) else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = max(bounds.width, bounds.height) * 0.75
        
        context.drawRadialGradient(gradient, startCenter: center, startRadius: radius * 0.6, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])
    }
}

// MARK: - Weather Module

struct MIRainDrop: Sendable {
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var length: CGFloat
    var opacity: CGFloat
}

struct MIShootingStar: Sendable {
    var startPos: CGPoint
    var currentPos: CGPoint
    var vector: CGPoint
    var progress: CGFloat
}

/// Gestisce effetti meteo: pioggia e stelle cadenti
/// NOTA: Questa classe deve essere usata solo dal main thread
class MIWeather {
    
    private var drops: [MIRainDrop] = []
    private var shootingStars: [MIShootingStar] = []
    private var pixelSize: CGFloat
    private var bounds: CGRect
    private let isPreview: Bool
    
    var isRaining: Bool = false
    private var timeSinceToggle: TimeInterval = 0
    private var rainIntensity: CGFloat = 0.0
    
    init(pixelSize: CGFloat, bounds: CGRect, isPreview: Bool = false) {
        self.pixelSize = pixelSize
        self.bounds = bounds
        self.isPreview = isPreview
    }
    
    func update(deltaTime: TimeInterval) {
        timeSinceToggle += deltaTime
        
        if timeSinceToggle > Double.random(in: 30...60) {
            isRaining.toggle()
            timeSinceToggle = 0
        }
        
        let targetIntensity: CGFloat = isRaining ? 1.0 : 0.0
        if rainIntensity < targetIntensity {
            rainIntensity += CGFloat(deltaTime) * 0.3
        } else if rainIntensity > targetIntensity {
            rainIntensity -= CGFloat(deltaTime) * 0.3
        }
        
        if rainIntensity > 0.01 {
            // In preview, meno gocce di pioggia
            let baseSpawnCount = isPreview ? 3 : 10
            let spawnCount = Int(CGFloat(baseSpawnCount) * rainIntensity)
            for _ in 0..<spawnCount {
                let drop = MIRainDrop(
                    x: CGFloat.random(in: 0...bounds.width),
                    y: bounds.height + CGFloat.random(in: 0...50),
                    speed: CGFloat.random(in: 500...800),
                    length: CGFloat.random(in: 10...20),
                    opacity: CGFloat.random(in: 0.3...0.6)
                )
                drops.append(drop)
            }
            
            for i in (0..<drops.count).reversed() {
                drops[i].y -= drops[i].speed * CGFloat(deltaTime)
                drops[i].x -= 50 * CGFloat(deltaTime)
                if drops[i].y < -20 {
                    drops.remove(at: i)
                }
            }
        } else {
            drops.removeAll()
        }
        
        if rainIntensity < 0.1 {
            if Double.random(in: 0...1.0) < 0.002 {
                spawnShootingStar()
            }
            
            for i in (0..<shootingStars.count).reversed() {
                shootingStars[i].progress += CGFloat(deltaTime) * 1.0
                let vec = shootingStars[i].vector
                shootingStars[i].currentPos.x += vec.x * CGFloat(deltaTime) * 600
                shootingStars[i].currentPos.y += vec.y * CGFloat(deltaTime) * 600
                
                if shootingStars[i].progress >= 1.0 {
                    shootingStars.remove(at: i)
                }
            }
        }
    }
    
    private func spawnShootingStar() {
        let startX = CGFloat.random(in: 0...bounds.width)
        let startY = CGFloat.random(in: bounds.height*0.5...bounds.height)
        let angle = CGFloat.random(in: 3.14...4.71)
        let vec = CGPoint(x: cos(angle), y: sin(angle))
        
        shootingStars.append(MIShootingStar(
            startPos: CGPoint(x: startX, y: startY),
            currentPos: CGPoint(x: startX, y: startY),
            vector: vec,
            progress: 0.0
        ))
    }
    
    func draw(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let r = env.skyTop.r; let g = env.skyTop.g; let b = env.skyTop.b; let brightness = (r + g + b) / 3.0
        if brightness < 0.4 && rainIntensity < 0.1 {
            context.saveGState()
            context.setStrokeColor(NSColor.white.cgColor)
            context.setLineWidth(2.0)
            context.setLineCap(.round)
            
            for star in shootingStars {
                context.setAlpha(1.0 - star.progress)
                context.move(to: star.startPos)
                context.addLine(to: star.currentPos)
                context.strokePath()
            }
            context.restoreGState()
        }
        
        if rainIntensity > 0.01 {
            context.saveGState()
            let rainColor = NSColor(calibratedRed: 0.7, green: 0.8, blue: 1.0, alpha: 1.0)
            context.setStrokeColor(rainColor.cgColor)
            context.setLineWidth(1.0)
            
            for drop in drops {
                context.setAlpha(drop.opacity * rainIntensity * 0.7)
                let start = CGPoint(x: drop.x, y: drop.y)
                let end = CGPoint(x: drop.x - 2, y: drop.y - drop.length)
                context.move(to: start)
                context.addLine(to: end)
                context.strokePath()
            }
            
            if rainIntensity > 0 {
                context.setFillColor(NSColor.gray.withAlphaComponent(0.3 * rainIntensity).cgColor)
                context.fill(bounds)
            }
            context.restoreGState()
        }
    }
}
