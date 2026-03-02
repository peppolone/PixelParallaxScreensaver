import Cocoa
import ScreenSaver

@objc(PixelParallaxView) class PixelParallaxView: ScreenSaverView {
    
    // MARK: - Constants
    private var pixelSize: CGFloat = 3.0  // Will be adjusted based on screen size
    private let dayDuration: TimeInterval = 240.0  // 4 minuti per ciclo completo
    
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
    private var hasRenderedPreviewFrame: Bool = false
    
    // MARK: - Benchmark
    private let benchmarkWindowSize: Int = 300
    private let benchmarkLogCadence: Int = 300
    private let layerProfileCadence: Int = 120
    private var frameTimeSamplesMs: [Double] = []
    private var renderTimeSamplesMs: [Double] = []
    private var approxFramebufferBytesPerFrame: Int = 0
    private let deviceColorSpace = CGColorSpaceCreateDeviceRGB()
    private let scanlineColor = NSColor.black.withAlphaComponent(0.15).cgColor
    private lazy var vignetteGradient: CGGradient? = {
        let gradientLocations: [CGFloat] = [0.0, 0.8, 1.0]
        let gradientColors = [
            NSColor.clear.cgColor,
            NSColor.black.withAlphaComponent(0.4).cgColor,
            NSColor.black.cgColor
        ] as CFArray
        return CGGradient(colorsSpace: deviceColorSpace, colors: gradientColors, locations: gradientLocations)
    }()
    private var cachedScanlineImage: CGImage?
    private var cachedScanlineSize: CGSize = .zero
    private var cachedVignetteImage: CGImage?
    private var cachedVignetteSize: CGSize = .zero

    // MARK: - Sky layer cache (sky+stars+celestial+mountains+clouds change very slowly)
    private var cachedSkyBgImage: CGImage?
    private var cachedSkyBgSize: CGSize = .zero
    private var skyCacheCounter: Int = 0
    private let skyCacheInterval: Int = 8  // refresh every 8 frames (sky+stars+mountains change very slowly)
    
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
    
    // MARK: - Configuration
    override var hasConfigureSheet: Bool {
        return true
    }
    
    override var configureSheet: NSWindow? {
        return MIConfigureSheetController.shared.configureSheet()
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
        if isInPreview && hasRenderedPreviewFrame {
            return
        }

        let frameStartTime = CACurrentMediaTime()
        frameCount += 1
        let shouldProfileLayers = frameCount % layerProfileCadence == 0
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
        
        let renderStartTime = CACurrentMediaTime()
        autoreleasepool {
            renderWithBackground(profileLayers: shouldProfileLayers)
        }
        let renderDurationMs = (CACurrentMediaTime() - renderStartTime) * 1000.0
        let frameDurationMs = (CACurrentMediaTime() - frameStartTime) * 1000.0
        recordBenchmark(frameDurationMs: frameDurationMs, renderDurationMs: renderDurationMs)

        if isInPreview {
            hasRenderedPreviewFrame = true
        }
    }
    
    private func renderWithBackground(profileLayers: Bool = false) {
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        
        guard width > 0 && height > 0 else { return }
        let bytesPerRow = width * 4
        approxFramebufferBytesPerFrame = bytesPerRow * height
        
        let contextCreateStart = profileLayers ? CACurrentMediaTime() : 0
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: deviceColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            NSLog("PixelParallaxView: Failed to create CGContext!")
            return
        }
        let contextCreateMs = profileLayers ? (CACurrentMediaTime() - contextCreateStart) * 1000.0 : 0.0
        
        // Pixel art settings
        context.setShouldAntialias(false)
        context.interpolationQuality = .none
        
        // Calculate environment
        let currentEnv = calculateEnvironment()
        
        // Sky cache: rebuild every skyCacheInterval frames (sky changes very slowly)
        let currentSize = CGSize(width: width, height: height)
        let needsSkyRebuild = (skyCacheCounter % skyCacheInterval == 0)
            || cachedSkyBgImage == nil
            || cachedSkyBgSize != currentSize
        skyCacheCounter += 1

        let skyBgRebuildStart = profileLayers ? CACurrentMediaTime() : 0
        if needsSkyRebuild {
            if let offCtx = CGContext(
                data: nil, width: width, height: height,
                bitsPerComponent: 8, bytesPerRow: bytesPerRow,
                space: deviceColorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ) {
                offCtx.setShouldAntialias(false)
                offCtx.interpolationQuality = .none
                // Cache sky gradient + stars only (most stable elements)
                background.drawSky(context: offCtx, bounds: bounds, env: currentEnv)
                background.drawStars(context: offCtx, bounds: bounds, env: currentEnv)
                cachedSkyBgImage = offCtx.makeImage()
                cachedSkyBgSize = currentSize
            }
        }
        // Fast blit of cached sky (~0.05ms vs ~8ms full redraw)
        if let skyImg = cachedSkyBgImage {
            context.draw(skyImg, in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        }
        let skyMs = profileLayers ? (CACurrentMediaTime() - skyBgRebuildStart) * 1000.0 : 0.0
        let starsMs = 0.0

        // Correct layer order: celestial (sun/moon) drawn BEHIND mountains
        let celestialMs = profileSection(profileLayers) {
            background.drawCelestialBody(context: context, bounds: bounds, env: currentEnv, cycleTime: CGFloat(cycleTime))
        }
        let mountainsMs = profileSection(profileLayers) {
            background.drawMountains(context: context, bounds: bounds, env: currentEnv)
        }
        let cloudsMs = profileSection(profileLayers) {
            background.drawClouds(context: context, bounds: bounds, env: currentEnv)
        }

        let beachBackgroundMs = profileSection(profileLayers) {
            scenery.drawBeachBackground(context: context, bounds: bounds, env: currentEnv)
        }
        let monkeyIslandMs = profileSection(profileLayers) {
            scenery.drawMonkeyIsland(context: context, bounds: bounds, env: currentEnv)
        }
        let seaMs = profileSection(profileLayers) {
            scenery.drawSea(context: context, bounds: bounds, env: currentEnv)
        }
        let seaCreaturesMs = profileSection(profileLayers) {
            scenery.drawSeaCreatures(context: context, bounds: bounds, env: currentEnv)
        }
        let mountainReflectionMs = profileSection(profileLayers) {
            background.drawMountainReflection(context: context, bounds: bounds, env: currentEnv)
        }
        let monkeyReflectionMs = profileSection(profileLayers) {
            scenery.drawMonkeyIslandReflection(context: context, bounds: bounds, env: currentEnv)
        }
        let beachForegroundMs = profileSection(profileLayers) {
            scenery.drawSinuousBeachForeground(context: context, bounds: bounds, env: currentEnv)
        }
        let shipMs = profileSection(profileLayers) {
            scenery.drawShip(context: context, bounds: bounds, env: currentEnv)
        }

        let bonfireMs = profileSection(profileLayers) {
            scenery.drawBonfire(context: context, bounds: bounds, env: currentEnv)
        }
        let charactersMs = profileSection(profileLayers) {
            characters.drawAll(context: context, bounds: bounds)
        }
        let palmsMs = profileSection(profileLayers) {
            scenery.drawPalms(context: context, bounds: bounds, env: currentEnv)
        }
        let firefliesMs = profileSection(profileLayers) {
            scenery.drawFireflies(context: context, bounds: bounds, env: currentEnv)
        }
        let weatherMs = profileSection(profileLayers) {
            weather.draw(context: context, bounds: bounds, env: currentEnv)
        }

        let scanlinesMs = profileSection(profileLayers) {
            drawScanlines(context: context, bounds: bounds)
        }
        let vignetteMs = profileSection(profileLayers) {
            drawVignette(context: context, bounds: bounds)
        }

        let skyBackgroundMs = skyMs + starsMs + celestialMs + mountainsMs + cloudsMs
        let midgroundMs = beachBackgroundMs + monkeyIslandMs + seaMs + seaCreaturesMs + mountainReflectionMs + monkeyReflectionMs + beachForegroundMs + shipMs
        let actorsWeatherMs = bonfireMs + charactersMs + palmsMs + firefliesMs + weatherMs
        let postFxMs = scanlinesMs + vignetteMs

        let commitMs = profileSection(profileLayers) {
            if let image = context.makeImage() {
                CATransaction.begin()
                CATransaction.setDisableActions(true)
                drawingLayer?.contents = image
                CATransaction.commit()
            }
        }

        if profileLayers {
            let sectionTotalMs = contextCreateMs + skyBackgroundMs + midgroundMs + actorsWeatherMs + postFxMs + commitMs
            let hotspots: [(String, Double)] = [
                ("sky", skyMs),
                ("stars", starsMs),
                ("celestial", celestialMs),
                ("mountains", mountainsMs),
                ("clouds", cloudsMs),
                ("sea", seaMs),
                ("seaCreatures", seaCreaturesMs),
                ("beachFg", beachForegroundMs),
                ("monkeyRefl", monkeyReflectionMs),
                ("ship", shipMs),
                ("chars", charactersMs),
                ("weather", weatherMs),
                ("scanlines", scanlinesMs),
                ("vignette", vignetteMs)
            ]
            let topHotspots = hotspots
                .sorted { $0.1 > $1.1 }
                .prefix(3)
                .map { "\($0.0)=\(String(format: "%.2f", $0.1))ms" }
                .joined(separator: ",")
            let contextText = String(format: "%.2f", contextCreateMs)
            let skyText = String(format: "%.2f", skyBackgroundMs)
            let midText = String(format: "%.2f", midgroundMs)
            let actorsText = String(format: "%.2f", actorsWeatherMs)
            let postFxText = String(format: "%.2f", postFxMs)
            let commitText = String(format: "%.2f", commitMs)
            let totalText = String(format: "%.2f", sectionTotalMs)
            NSLog("PixelParallax LayerProfile frame=\(frameCount) ctx=\(contextText)ms skyBg=\(skyText)ms mid=\(midText)ms actors=\(actorsText)ms postFx=\(postFxText)ms commit=\(commitText)ms total=\(totalText)ms top=[\(topHotspots)]")
        }
    }
    
    private func renderSimpleGradient() {
        let width = Int(bounds.width)
        let height = Int(bounds.height)
        
        guard width > 0 && height > 0 else { return }
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: deviceColorSpace,
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
        
        let gradient = CGGradient(colorsSpace: deviceColorSpace, colors: [bottomColor, topColor] as CFArray, locations: [0, 1])!
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
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: deviceColorSpace,
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
        background.drawCelestialBody(context: context, bounds: bounds, env: currentEnv, cycleTime: CGFloat(cycleTime))
        background.drawMountains(context: context, bounds: bounds, env: currentEnv)
        background.drawClouds(context: context, bounds: bounds, env: currentEnv)
        
        scenery.drawBeachBackground(context: context, bounds: bounds, env: currentEnv)
        scenery.drawMonkeyIsland(context: context, bounds: bounds, env: currentEnv)
        scenery.drawSea(context: context, bounds: bounds, env: currentEnv)
        scenery.drawSeaCreatures(context: context, bounds: bounds, env: currentEnv)
        background.drawMountainReflection(context: context, bounds: bounds, env: currentEnv)
        scenery.drawMonkeyIslandReflection(context: context, bounds: bounds, env: currentEnv)
        scenery.drawSinuousBeachForeground(context: context, bounds: bounds, env: currentEnv)
        scenery.drawShip(context: context, bounds: bounds, env: currentEnv)
        
        scenery.drawBonfire(context: context, bounds: bounds, env: currentEnv)
        characters.drawAll(context: context, bounds: bounds)
        scenery.drawPalms(context: context, bounds: bounds, env: currentEnv)
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
        if let scanlineImage = scanlineImage(for: bounds) {
            context.draw(scanlineImage, in: bounds)
        }
        context.restoreGState()
    }
    
    private func drawVignette(context: CGContext, bounds: CGRect) {
        guard let vignetteImage = vignetteImage(for: bounds) else { return }
        context.draw(vignetteImage, in: bounds)
    }

    private func scanlineImage(for bounds: CGRect) -> CGImage? {
        let size = bounds.size
        if cachedScanlineImage == nil || cachedScanlineSize != size {
            let width = Int(size.width)
            let height = Int(size.height)
            guard width > 0, height > 0 else { return nil }

            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: deviceColorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ) else {
                return nil
            }

            context.setFillColor(scanlineColor)
            for y in stride(from: 0, through: CGFloat(height), by: 4) {
                context.fill(CGRect(x: 0, y: y, width: CGFloat(width), height: 2))
            }

            cachedScanlineImage = context.makeImage()
            cachedScanlineSize = size
        }

        return cachedScanlineImage
    }

    private func vignetteImage(for bounds: CGRect) -> CGImage? {
        let size = bounds.size
        if cachedVignetteImage == nil || cachedVignetteSize != size {
            let width = Int(size.width)
            let height = Int(size.height)
            guard width > 0, height > 0 else { return nil }

            guard let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: deviceColorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
            ) else {
                return nil
            }

            guard let gradient = vignetteGradient else { return nil }
            let center = CGPoint(x: CGFloat(width) * 0.5, y: CGFloat(height) * 0.5)
            let radius = max(CGFloat(width), CGFloat(height)) * 0.75
            context.drawRadialGradient(gradient, startCenter: center, startRadius: radius * 0.6, endCenter: center, endRadius: radius, options: [.drawsAfterEndLocation])

            cachedVignetteImage = context.makeImage()
            cachedVignetteSize = size
        }

        return cachedVignetteImage
    }

    @inline(__always)
    private func profileSection(_ enabled: Bool, _ block: () -> Void) -> Double {
        if !enabled {
            block()
            return 0
        }

        let start = CACurrentMediaTime()
        block()
        return (CACurrentMediaTime() - start) * 1000.0
    }
    
    private func recordBenchmark(frameDurationMs: Double, renderDurationMs: Double) {
        frameTimeSamplesMs.append(frameDurationMs)
        renderTimeSamplesMs.append(renderDurationMs)
        
        if frameTimeSamplesMs.count > benchmarkWindowSize {
            frameTimeSamplesMs.removeFirst(frameTimeSamplesMs.count - benchmarkWindowSize)
        }
        if renderTimeSamplesMs.count > benchmarkWindowSize {
            renderTimeSamplesMs.removeFirst(renderTimeSamplesMs.count - benchmarkWindowSize)
        }
        
        if frameCount % benchmarkLogCadence == 0 {
            logBenchmarkSummary()
        }
    }
    
    private func logBenchmarkSummary() {
        guard !frameTimeSamplesMs.isEmpty, !renderTimeSamplesMs.isEmpty else { return }
        
        let avgFrameMs = frameTimeSamplesMs.reduce(0, +) / Double(frameTimeSamplesMs.count)
        let avgRenderMs = renderTimeSamplesMs.reduce(0, +) / Double(renderTimeSamplesMs.count)
        let p95FrameMs = percentile(frameTimeSamplesMs, p: 0.95)
        let approxFps = avgFrameMs > 0 ? 1000.0 / avgFrameMs : 0
        let framebufferMB = Double(approxFramebufferBytesPerFrame) / (1024.0 * 1024.0)
        let approxFrameBufferThroughputMBs = framebufferMB * approxFps
        
        let recommendation: String
        if p95FrameMs <= 16.6 {
            recommendation = "candidate-60fps"
        } else if p95FrameMs <= 33.3 {
            recommendation = "stable-30fps"
        } else {
            recommendation = "optimize-before-30fps"
        }
        
        let avgFrameText = String(format: "%.2f", avgFrameMs)
        let p95Text = String(format: "%.2f", p95FrameMs)
        let avgRenderText = String(format: "%.2f", avgRenderMs)
        let fpsText = String(format: "%.1f", approxFps)
        let framebufferText = String(format: "%.2f", framebufferMB)
        let throughputText = String(format: "%.1f", approxFrameBufferThroughputMBs)
        
        NSLog(
            "PixelParallax Benchmark frames=\(frameTimeSamplesMs.count) avgFrame=\(avgFrameText)ms p95=\(p95Text)ms avgRender=\(avgRenderText)ms fps=\(fpsText) fb=\(framebufferText)MB alloc=\(throughputText)MB/s rec=\(recommendation)"
        )
    }
    
    private func percentile(_ values: [Double], p: Double) -> Double {
        guard !values.isEmpty else { return 0 }
        let sorted = values.sorted()
        let clampedPercentile = max(0.0, min(1.0, p))
        let index = Int((Double(sorted.count - 1) * clampedPercentile).rounded())
        return sorted[index]
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
        
        let rainEnabled = MIConfigureSheetController.shared.isRainEnabled
        if !rainEnabled {
            isRaining = false
            timeSinceToggle = 0
        } else if timeSinceToggle > Double.random(in: 30...60) {
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
