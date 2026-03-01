import Cocoa
import ScreenSaver

struct MIStar: Sendable {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var twinklePhase: CGFloat
    var twinkleSpeed: CGFloat
}

struct MICloud: Sendable {
    var x: CGFloat
    var y: CGFloat
    var speed: CGFloat
    var spriteType: String  // "cloud_small", "cloud", "cloud_large"
}

/// Gestisce il rendering del cielo, stelle, nuvole e elementi di sfondo
/// NOTA: Questa classe deve essere usata solo dal main thread
class MIBackground {

    private struct RGBAKey: Equatable {
        let r: Int
        let g: Int
        let b: Int
        let a: Int
    }

    private struct ColorPairKey: Equatable {
        let first: RGBAKey
        let second: RGBAKey

        init(first: NSColor, second: NSColor) {
            self.first = MIBackground.quantizedRGBA(first)
            self.second = MIBackground.quantizedRGBA(second)
        }
    }

    private static func quantizedRGBA(_ color: NSColor) -> RGBAKey {
        let rgb = color.usingColorSpace(.deviceRGB) ?? color
        return RGBAKey(
            r: Int((rgb.redComponent * 255).rounded()),
            g: Int((rgb.greenComponent * 255).rounded()),
            b: Int((rgb.blueComponent * 255).rounded()),
            a: Int((rgb.alphaComponent * 255).rounded())
        )
    }
    
    private var stars: [MIStar] = []
    private var cloudsBack: [MICloud] = []
    private var cloudsFront: [MICloud] = []
    
    /// Scala pixel uniforme per TUTTI gli sprite (no ridimensionamento dinamico)
    /// Questo mantiene la coerenza pixel art
    private let spriteScale: CGFloat = 2.0
    
    /// Sprite delle nuvole caricati da Assets
    /// Chiave: nome sprite, Valore: CGImage
    private var cloudSprites: [String: CGImage] = [:]
    
    private var starOffset: CGFloat = 0
    private var mountainOffset: CGFloat = 0
    private let deviceColorSpace = CGColorSpaceCreateDeviceRGB()
    private var cachedSkyGradient: (key: ColorPairKey, gradient: CGGradient)?
    private var cachedCelestialGlowGradient: (key: ColorPairKey, gradient: CGGradient)?
    
    let pixelSize: CGFloat
    private var time: CGFloat = 0
    private let isPreview: Bool
    
    init(pixelSize: CGFloat, bounds: CGRect, isPreview: Bool = false) {
        self.pixelSize = pixelSize
        self.isPreview = isPreview
        loadCloudSprites()
        generateStars(bounds: bounds)
        generateClouds(bounds: bounds)
    }
    
    /// Carica tutti gli sprite delle nuvole da Assets
    /// Naming convention: cloud_small.png, cloud.png, cloud_large.png
    private func loadCloudSprites() {
        let cloudNames = ["cloud_small", "cloud", "cloud_large"]
        
        for name in cloudNames {
            if let sprite = MISpriteLoader.shared.loadSprite(named: name) {
                cloudSprites[name] = sprite
                NSLog("MIBackground: Loaded \(name) sprite")
            }
        }
        
        if cloudSprites.isEmpty {
            NSLog("MIBackground: No cloud sprites found, using procedural clouds")
        }
    }
    
    private func generateStars(bounds: CGRect) {
        // In preview, mostra solo 30 stelle invece di 150
        let starCount = isPreview ? 30 : 150
        
        for _ in 0..<starCount {
            stars.append(MIStar(
                x: CGFloat.random(in: 0...bounds.width * 2),
                y: CGFloat.random(in: bounds.height * 0.4...bounds.height),
                size: CGFloat.random(in: 1...2) * pixelSize,
                twinklePhase: CGFloat.random(in: 0...6.28),
                twinkleSpeed: CGFloat.random(in: 0.05...0.2)
            ))
        }
    }
    
    private func generateClouds(bounds: CGRect) {
        // In preview, mostra solo 2 nuvole invece di 5
        let cloudCount = isPreview ? 2 : 5
        
        // Nuvole di sfondo (cloud_small) - più alte, più lente
        for _ in 0..<cloudCount {
            cloudsBack.append(MICloud(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: bounds.height * 0.6...bounds.height * 0.85),
                speed: 0.15,
                spriteType: "cloud_small"
            ))
        }
        
        // Nuvole medie (cloud) 
        for _ in 0..<3 {
            cloudsBack.append(MICloud(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: bounds.height * 0.5...bounds.height * 0.75),
                speed: 0.25,
                spriteType: "cloud"
            ))
        }
        
        // Nuvole in primo piano (cloud_large) - più basse, più veloci
        for _ in 0..<2 {
            cloudsFront.append(MICloud(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: bounds.height * 0.55...bounds.height * 0.7),
                speed: 0.35,
                spriteType: "cloud_large"
            ))
        }

    }
    
    func update(deltaTime: CGFloat) {
        time += deltaTime
        starOffset += 0.05
        
        for i in 0..<stars.count {
            stars[i].twinklePhase += stars[i].twinkleSpeed * deltaTime
        }
        
        for i in 0..<cloudsBack.count {
            cloudsBack[i].x += cloudsBack[i].speed
        }
        for i in 0..<cloudsFront.count {
            cloudsFront[i].x += cloudsFront[i].speed
        }
    }
    
    func drawSky(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        guard let gradient = skyGradient(top: env.skyTop.nsColor, bottom: env.skyBottom.nsColor) else { return }
        context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: bounds.height), end: CGPoint(x: 0, y: 0), options: [])
    }
    
    func drawStars(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        // Simplified version - always draw stars with fixed visibility
        let starVisibility: CGFloat = 0.8
        
        for star in stars {
            var drawX = star.x - starOffset
            let wrap = bounds.width * 2
            if wrap > 0 {
                while drawX < 0 { drawX += wrap }
                drawX = drawX.truncatingRemainder(dividingBy: wrap)
            }
            
            let alpha = max(0, min(1, (sin(star.twinklePhase) * 0.5 + 0.5) * starVisibility))
            let color = NSColor(white: 1.0, alpha: alpha)
            context.setFillColor(color.cgColor)
            context.fill(CGRect(x: drawX, y: star.y, width: star.size, height: star.size))
        }
    }
    
    func drawCelestialBody(context: CGContext, bounds: CGRect, env: MIPalette.Environment, cycleTime: CGFloat = 0.5) {
        // cycleTime: 0.0-1.0 rappresenta il ciclo completo giorno/notte
        
        let horizonY = bounds.height * 0.35  // Linea dell'orizzonte
        let maxHeight = bounds.height * 0.9  // Altezza massima
        let belowHorizon = bounds.height * 0.15  // Quanto scende sotto l'orizzonte
        let radius: CGFloat = 40.0 * (pixelSize / 2.0)
        
        // Il sole è visibile da 0.15 a 0.85 (più tempo per attraversare l'orizzonte)
        // La luna è visibile da 0.90 a 1.00 + 0.00 a 0.10
        
        let isDay = cycleTime >= 0.15 && cycleTime <= 0.85
        
        if isDay {
            // SOLE: movimento ad arco che attraversa completamente l'orizzonte
            let sunProgress = (cycleTime - 0.15) / 0.70  // 0 -> 1
            
            // X: da sinistra a destra
            let sunX = bounds.width * (0.05 + sunProgress * 0.90)
            
            // Y: arco parabolico che va SOTTO l'orizzonte all'inizio e alla fine
            // sin(0) = 0, sin(pi/2) = 1, sin(pi) = 0
            // Modifichiamo per far partire e finire sotto l'orizzonte
            let arcProgress = sunProgress * .pi  // 0 -> pi
            let sunHeight = sin(arcProgress) * (maxHeight - horizonY + belowHorizon)
            let sunY = (horizonY - belowHorizon) + sunHeight
            
            // Nessuna dissolvenza - il sole è sempre visibile finché non è completamente sotto
            let alpha: CGFloat = sunY > horizonY * 0.2 ? 1.0 : max(0, sunY / (horizonY * 0.2))
            
            drawCelestialBodyAt(context: context, cx: sunX, cy: sunY, radius: radius, env: env, isMoon: false, alpha: alpha)
        } else if cycleTime >= 0.65 || cycleTime <= 0.35 {
            // LUNA: stessa durata di traversata del sole (0.70) per velocità coerente
            var moonProgress: CGFloat
            if cycleTime >= 0.65 {
                moonProgress = (cycleTime - 0.65) / 0.70
            } else {
                moonProgress = (cycleTime + 0.35) / 0.70
            }
            moonProgress = max(0, min(1, moonProgress))
            
            // X: da sinistra a destra
            let moonX = bounds.width * (0.1 + moonProgress * 0.8)
            
            // Y: arco parabolico
            let moonHeight = sin(moonProgress * .pi) * (maxHeight - horizonY + belowHorizon)
            let moonY = (horizonY - belowHorizon) + moonHeight
            
            let alpha: CGFloat = moonY > horizonY * 0.2 ? 1.0 : max(0, moonY / (horizonY * 0.2))
            
            drawCelestialBodyAt(context: context, cx: moonX, cy: moonY, radius: radius, env: env, isMoon: true, alpha: alpha)
        }
    }
    
    private func drawCelestialBodyAt(context: CGContext, cx: CGFloat, cy: CGFloat, radius: CGFloat, env: MIPalette.Environment, isMoon: Bool, alpha: CGFloat) {
        if alpha <= 0 { return }
        
        context.saveGState()
        context.setAlpha(alpha)
        
        // Glow
        context.saveGState()
        context.setBlendMode(.screen)
        let glowRadius = radius * 3.0
        if let gradient = celestialGlowGradient(baseColor: env.sunMoonGlow.nsColor) {
            context.drawRadialGradient(gradient, startCenter: CGPoint(x: cx, y: cy), startRadius: radius * 0.5, endCenter: CGPoint(x: cx, y: cy), endRadius: glowRadius, options: .drawsBeforeStartLocation)
        }
        context.restoreGState()
        
        // Corpo celeste
        context.setFillColor(env.sunMoon.nsColor.cgColor)
        context.fillEllipse(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
        
        // Crateri sulla luna
        if isMoon {
            let craterColor = env.sunMoon.nsColor.blended(withFraction: 0.15, of: .gray) ?? env.sunMoon.nsColor
            context.setFillColor(craterColor.cgColor)
            context.fillEllipse(in: CGRect(x: cx - radius * 0.3, y: cy + radius * 0.2, width: radius * 0.25, height: radius * 0.25))
            context.fillEllipse(in: CGRect(x: cx + radius * 0.25, y: cy - radius * 0.1, width: radius * 0.18, height: radius * 0.18))
            context.fillEllipse(in: CGRect(x: cx - radius * 0.05, y: cy - radius * 0.35, width: radius * 0.12, height: radius * 0.12))
        }
        
        context.restoreGState()
    }

    private func skyGradient(top: NSColor, bottom: NSColor) -> CGGradient? {
        let key = ColorPairKey(first: top, second: bottom)
        if let cached = cachedSkyGradient, cached.key == key {
            return cached.gradient
        }

        let colors = [top.cgColor, bottom.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: deviceColorSpace, colors: colors, locations: locations) else { return nil }
        cachedSkyGradient = (key, gradient)
        return gradient
    }

    private func celestialGlowGradient(baseColor: NSColor) -> CGGradient? {
        let transparent = baseColor.withAlphaComponent(0)
        let key = ColorPairKey(first: baseColor, second: transparent)
        if let cached = cachedCelestialGlowGradient, cached.key == key {
            return cached.gradient
        }

        let colors = [baseColor.cgColor, transparent.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: deviceColorSpace, colors: colors, locations: locations) else { return nil }
        cachedCelestialGlowGradient = (key, gradient)
        return gradient
    }
    
    func drawMountains(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let yBase = bounds.height * 0.35
        
        let wrap = bounds.width + 200
        var x = -mountainOffset.truncatingRemainder(dividingBy: wrap)
        if x > 0 { x -= wrap }
        
        drawSingleMountainChain(context: context, xOffset: x, yBase: yBase, bounds: bounds, env: env)
        drawSingleMountainChain(context: context, xOffset: x + wrap, yBase: yBase, bounds: bounds, env: env)

        // Due layer piccoli a destra dell'isola principale
        let rightLayerOneColor = env.distantIsland.nsColor.blended(withFraction: 0.2, of: .black) ?? env.distantIsland.nsColor
        let rightLayerTwoColor = env.distantIsland.nsColor.blended(withFraction: 0.35, of: .black) ?? env.distantIsland.nsColor
        drawRightMountainLayer(context: context, bounds: bounds, yBase: yBase, env: env, color: rightLayerOneColor, startXRatio: 0.86, widthRatio: 0.24, heightRatio: 0.09, shadeAlpha: 0.2)
        drawRightMountainLayer(context: context, bounds: bounds, yBase: yBase, env: env, color: rightLayerTwoColor, startXRatio: 0.91, widthRatio: 0.2, heightRatio: 0.12, shadeAlpha: 0.16)
    }
    
    private func drawSingleMountainChain(
        context: CGContext,
        xOffset: CGFloat,
        yBase: CGFloat,
        bounds: CGRect,
        env: MIPalette.Environment,
        color: NSColor? = nil,
        xScale: CGFloat = 1.0,
        yScale: CGFloat = 1.0,
        shadeAlpha: CGFloat = 0.3
    ) {
        let baseColor = color ?? env.distantIsland.nsColor
        context.setFillColor(baseColor.cgColor)
        
        let points: [(CGFloat, CGFloat)] = [
            (0, 0), (100, 50), (250, 20), (400, 120), (600, 40), (800, 90), (1000, 10), (1200, 0)
        ]
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: xOffset, y: yBase))
        
        for p in points {
            path.addLine(to: CGPoint(x: xOffset + p.0 * (pixelSize/3) * xScale, y: yBase + p.1 * (pixelSize/3) * yScale))
        }
        
        path.addLine(to: CGPoint(x: xOffset + 1200 * (pixelSize/3) * xScale, y: yBase))
        path.closeSubpath()
        context.addPath(path)
        context.fillPath()
        
        context.saveGState()
        context.setBlendMode(.sourceAtop)
        context.setFillColor(env.skyBottom.nsColor.withAlphaComponent(shadeAlpha).cgColor)
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
    }

    private func drawRightMountainLayer(
        context: CGContext,
        bounds: CGRect,
        yBase: CGFloat,
        env: MIPalette.Environment,
        color: NSColor,
        startXRatio: CGFloat,
        widthRatio: CGFloat,
        heightRatio: CGFloat,
        shadeAlpha: CGFloat
    ) {
        let startX = bounds.width * startXRatio
        let layerWidth = bounds.width * widthRatio
        let layerHeight = bounds.height * heightRatio

        let points: [(CGFloat, CGFloat)] = [
            (0.0, 0.0),
            (0.14, 0.35),
            (0.32, 0.12),
            (0.50, 0.55),
            (0.71, 0.18),
            (0.88, 0.28),
            (1.0, 0.0)
        ]

        let path = CGMutablePath()
        path.move(to: CGPoint(x: startX, y: yBase))
        for point in points {
            path.addLine(to: CGPoint(x: startX + point.0 * layerWidth, y: yBase + point.1 * layerHeight))
        }
        path.addLine(to: CGPoint(x: startX + layerWidth, y: yBase))
        path.closeSubpath()

        context.setFillColor(color.cgColor)
        context.addPath(path)
        context.fillPath()

        context.saveGState()
        context.setBlendMode(.sourceAtop)
        context.setFillColor(env.skyBottom.nsColor.withAlphaComponent(shadeAlpha).cgColor)
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
    }
    
    func drawMountainReflection(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let yBase = bounds.height * 0.35
        
        let wrap = bounds.width + 200
        var x = -mountainOffset.truncatingRemainder(dividingBy: wrap)
        if x > 0 { x -= wrap }
        
        context.saveGState()
        
        // CLIP FIRST BEFORE FLIPPING
        context.clip(to: CGRect(x: 0, y: 0, width: bounds.width, height: yBase))

        // Reflection translation: flip vertically around the horizon
        context.translateBy(x: 0, y: yBase)
        context.scaleBy(x: 1.0, y: -0.6)  // squish
        
        // Shear to simulate gentle waves as in the ship fallback
        var transform = CGAffineTransform.identity
        transform.c = 0.05 * sin(time * 2.0)
        context.concatenate(transform)
        
        context.translateBy(x: 0, y: -yBase)
        
        // Slightly dimmer alpha for reflections
        let isDark = env.skyTop.r < 0.3 && env.skyTop.g < 0.3
        context.setAlpha(isDark ? 0.3 : 0.15)
        
        drawSingleMountainChain(context: context, xOffset: x, yBase: yBase, bounds: bounds, env: env)
        drawSingleMountainChain(context: context, xOffset: x + wrap, yBase: yBase, bounds: bounds, env: env)

        let rightLayerOneColor = env.distantIsland.nsColor.blended(withFraction: 0.2, of: .black) ?? env.distantIsland.nsColor
        let rightLayerTwoColor = env.distantIsland.nsColor.blended(withFraction: 0.35, of: .black) ?? env.distantIsland.nsColor
        drawRightMountainLayer(context: context, bounds: bounds, yBase: yBase, env: env, color: rightLayerOneColor, startXRatio: 0.86, widthRatio: 0.24, heightRatio: 0.09, shadeAlpha: 0.2)
        drawRightMountainLayer(context: context, bounds: bounds, yBase: yBase, env: env, color: rightLayerTwoColor, startXRatio: 0.91, widthRatio: 0.2, heightRatio: 0.12, shadeAlpha: 0.16)
        
        context.restoreGState()
    }

    func drawClouds(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        // Nuvole disattivate temporaneamente su richiesta utente.
        _ = context
        _ = bounds
        _ = env
    }
    
    private func drawCloud(context: CGContext, cloud: MICloud, bounds: CGRect, env: MIPalette.Environment) {
        // Cerca lo sprite per questo tipo di nuvola
        if let sprite = cloudSprites[cloud.spriteType] {
            // Usa scala fissa per mantenere coerenza pixel art
            let spriteWidth = CGFloat(sprite.width) * spriteScale
            let totalWidth = bounds.width + spriteWidth * 2
            let wrappedX = ((cloud.x + spriteWidth).truncatingRemainder(dividingBy: totalWidth)) - spriteWidth
            
            // Disegna lo sprite con scala uniforme
            MISpriteLoader.drawSprite(sprite, in: context, at: wrappedX, y: cloud.y, scale: spriteScale, flipX: false)
        } else if let fallbackSprite = cloudSprites["cloud"] {
            // Fallback: usa cloud.png se lo sprite specifico non esiste
            let spriteWidth = CGFloat(fallbackSprite.width) * spriteScale
            let totalWidth = bounds.width + spriteWidth * 2
            let wrappedX = ((cloud.x + spriteWidth).truncatingRemainder(dividingBy: totalWidth)) - spriteWidth
            
            MISpriteLoader.drawSprite(fallbackSprite, in: context, at: wrappedX, y: cloud.y, scale: spriteScale, flipX: false)
        } else {
            // Fallback finale: nuvola procedurale
            drawCloudProcedural(context: context, cloud: cloud, bounds: bounds, env: env)
        }
    }
    
    /// Disegna una nuvola procedurale (fallback se nessuno sprite è disponibile)
    private func drawCloudProcedural(context: CGContext, cloud: MICloud, bounds: CGRect, env: MIPalette.Environment) {
        let w: CGFloat = 100  // Larghezza fissa per fallback
        let totalWidth = bounds.width + w * 2
        let wrappedX = ((cloud.x + w).truncatingRemainder(dividingBy: totalWidth)) - w
        
        let py = cloud.y
        let h = w * 0.45
        
        let baseColor = env.cloudColor.nsColor.cgColor
        context.setFillColor(baseColor)
        
        // Forma semplice a ellissi
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.25, y: py, width: w * 0.5, height: h * 0.9))
        context.fillEllipse(in: CGRect(x: wrappedX, y: py - h * 0.15, width: w * 0.4, height: h * 0.7))
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.6, y: py - h * 0.12, width: w * 0.4, height: h * 0.72))
    }

    private func drawComparisonCloud(context: CGContext, cloud: MICloud, bounds: CGRect, env: MIPalette.Environment) {
        if let sprite = cloudSprites["cloud"] ?? cloudSprites["cloud_small"] {
            let compareScale = spriteScale * 0.9
            let spriteWidth = CGFloat(sprite.width) * compareScale
            let spriteHeight = CGFloat(sprite.height) * compareScale
            let totalWidth = bounds.width + spriteWidth * 2
            let wrappedX = ((cloud.x + spriteWidth).truncatingRemainder(dividingBy: totalWidth)) - spriteWidth

            MISpriteLoader.drawSprite(sprite, in: context, at: wrappedX, y: cloud.y, scale: compareScale, flipX: false)

            let highlight = env.cloudColor.nsColor.withAlphaComponent(0.26).cgColor
            let softShade = env.skyBottom.nsColor.withAlphaComponent(0.16).cgColor
            let px = max(1, pixelSize * 1.5)

            context.setFillColor(highlight)
            context.fill(CGRect(x: wrappedX + spriteWidth * 0.22, y: cloud.y + spriteHeight * 0.62, width: px * 5, height: px))
            context.fill(CGRect(x: wrappedX + spriteWidth * 0.52, y: cloud.y + spriteHeight * 0.68, width: px * 4, height: px))

            context.setFillColor(softShade)
            context.fill(CGRect(x: wrappedX + spriteWidth * 0.18, y: cloud.y + spriteHeight * 0.2, width: px * 6, height: px))
            context.fill(CGRect(x: wrappedX + spriteWidth * 0.5, y: cloud.y + spriteHeight * 0.26, width: px * 5, height: px))
            return
        }

        let baseW: CGFloat = 96
        let w = baseW + (cloud.y.truncatingRemainder(dividingBy: 24))
        let h = w * 0.34
        let totalWidth = bounds.width + w * 2
        let wrappedX = ((cloud.x + w).truncatingRemainder(dividingBy: totalWidth)) - w
        let py = cloud.y

        let lightColor = env.cloudColor.nsColor.withAlphaComponent(0.72).cgColor
        let shadowColor = env.skyBottom.nsColor.withAlphaComponent(0.2).cgColor

        context.setFillColor(shadowColor)
        context.fill(CGRect(x: wrappedX + w * 0.12, y: py - h * 0.08, width: w * 0.76, height: h * 0.42))

        context.setFillColor(lightColor)
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.06, y: py, width: w * 0.28, height: h * 0.65))
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.28, y: py + h * 0.08, width: w * 0.34, height: h * 0.75))
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.54, y: py, width: w * 0.30, height: h * 0.62))
    }
}

// MARK: - MIColor Extensions per sfumature
extension MIColor {
    func lighter(by percentage: CGFloat) -> MIColor {
        let newR = min(1.0, r + (1.0 - r) * percentage)
        let newG = min(1.0, g + (1.0 - g) * percentage)
        let newB = min(1.0, b + (1.0 - b) * percentage)
        return MIColor(r: newR, g: newG, b: newB, a: a)
    }
    
    func darker(by percentage: CGFloat) -> MIColor {
        return MIColor(r: r * (1.0 - percentage), g: g * (1.0 - percentage), b: b * (1.0 - percentage), a: a)
    }
}
