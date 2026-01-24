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
    var width: CGFloat
    var type: Int
    var speed: CGFloat
}

/// Gestisce il rendering del cielo, stelle, nuvole e elementi di sfondo
/// NOTA: Questa classe deve essere usata solo dal main thread
class MIBackground {
    
    private var stars: [MIStar] = []
    private var cloudsBack: [MICloud] = []
    private var cloudsFront: [MICloud] = []
    
    private var starOffset: CGFloat = 0
    private var mountainOffset: CGFloat = 0
    
    let pixelSize: CGFloat
    private var time: CGFloat = 0
    private let isPreview: Bool
    
    init(pixelSize: CGFloat, bounds: CGRect, isPreview: Bool = false) {
        self.pixelSize = pixelSize
        self.isPreview = isPreview
        generateStars(bounds: bounds)
        generateClouds(bounds: bounds)
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
        
        for _ in 0..<cloudCount {
            cloudsBack.append(MICloud(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: bounds.height * 0.5...bounds.height * 0.8),
                width: CGFloat.random(in: 100...200),
                type: Int.random(in: 0...1),
                speed: 0.15
            ))
        }
        for _ in 0..<3 {
            cloudsFront.append(MICloud(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: bounds.height * 0.6...bounds.height * 0.9),
                width: CGFloat.random(in: 200...400),
                type: 2,
                speed: 0.35
            ))
        }
    }
    
    func update(deltaTime: CGFloat) {
        time += deltaTime
        starOffset += 0.05
        mountainOffset += 0.2
        
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
        let colors = [env.skyTop.nsColor.cgColor, env.skyBottom.nsColor.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) else { return }
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
    
    func drawCelestialBody(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let cx = bounds.width * 0.8
        let cy = bounds.height * 0.8
        let radius: CGFloat = 40.0 * (pixelSize / 2.0)
        
        context.saveGState()
        context.setBlendMode(.screen)
        let glowRadius = radius * 3.0
        
        let glowColors = [env.sunMoonGlow.nsColor.cgColor, env.sunMoonGlow.nsColor.withAlphaComponent(0).cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: glowColors, locations: locations) {
            context.drawRadialGradient(gradient, startCenter: CGPoint(x: cx, y: cy), startRadius: radius * 0.5, endCenter: CGPoint(x: cx, y: cy), endRadius: glowRadius, options: .drawsBeforeStartLocation)
        }
        context.restoreGState()
        
        context.setFillColor(env.sunMoon.nsColor.cgColor)
        context.fillEllipse(in: CGRect(x: cx - radius, y: cy - radius, width: radius * 2, height: radius * 2))
    }
    
    func drawMountains(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let yBase = bounds.height * 0.35
        
        let wrap = bounds.width + 200
        var x = -mountainOffset.truncatingRemainder(dividingBy: wrap)
        if x > 0 { x -= wrap }
        
        drawSingleMountainChain(context: context, xOffset: x, yBase: yBase, bounds: bounds, env: env)
        drawSingleMountainChain(context: context, xOffset: x + wrap, yBase: yBase, bounds: bounds, env: env)
    }
    
    private func drawSingleMountainChain(context: CGContext, xOffset: CGFloat, yBase: CGFloat, bounds: CGRect, env: MIPalette.Environment) {
        context.setFillColor(env.distantIsland.nsColor.cgColor)
        
        let points: [(CGFloat, CGFloat)] = [
            (0, 0), (100, 50), (250, 20), (400, 120), (600, 40), (800, 90), (1000, 10), (1200, 0)
        ]
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: xOffset, y: yBase))
        
        for p in points {
            path.addLine(to: CGPoint(x: xOffset + p.0 * (pixelSize/3), y: yBase + p.1 * (pixelSize/3)))
        }
        
        path.addLine(to: CGPoint(x: xOffset + 1200 * (pixelSize/3), y: yBase))
        path.closeSubpath()
        context.addPath(path)
        context.fillPath()
        
        context.saveGState()
        context.setBlendMode(.sourceAtop)
        context.setFillColor(env.skyBottom.nsColor.withAlphaComponent(0.3).cgColor)
        context.addPath(path)
        context.fillPath()
        context.restoreGState()
    }
    
    func drawClouds(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        for cloud in cloudsBack {
            drawCloud(context: context, cloud: cloud, bounds: bounds, env: env)
        }
        for cloud in cloudsFront {
            drawCloud(context: context, cloud: cloud, bounds: bounds, env: env)
        }
    }
    
    private func drawCloud(context: CGContext, cloud: MICloud, bounds: CGRect, env: MIPalette.Environment) {
        let totalWidth = bounds.width + cloud.width * 2
        let wrappedX = ((cloud.x + cloud.width).truncatingRemainder(dividingBy: totalWidth)) - cloud.width
        
        let py = cloud.y
        let w = cloud.width
        let h = w * 0.45
        
        // Colori per sfumatura: base, highlight (bordi più chiari), shadow (interno più scuro)
        let baseColor = env.cloudColor.nsColor.cgColor
        let highlightColor = env.cloudColor.lighter(by: 0.15).nsColor.cgColor
        let shadowColor = env.cloudColor.darker(by: 0.1).nsColor.cgColor
        
        // Struttura a "bolle" multiple in stile Monkey Island
        // Layer 1: Ombra interna (leggermente spostata in basso)
        context.setFillColor(shadowColor)
        let shadowOffset: CGFloat = h * 0.08
        
        // Bolla centrale grande (ombra)
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.25, y: py - shadowOffset, width: w * 0.5, height: h * 0.85))
        // Bolle laterali (ombre)
        context.fillEllipse(in: CGRect(x: wrappedX, y: py - h * 0.15 - shadowOffset, width: w * 0.4, height: h * 0.7))
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.6, y: py - h * 0.12 - shadowOffset, width: w * 0.4, height: h * 0.72))
        
        // Layer 2: Corpo principale della nuvola (colore base)
        context.setFillColor(baseColor)
        
        // Bolla grande centrale
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.25, y: py, width: w * 0.5, height: h * 0.9))
        // Bolla sinistra bassa
        context.fillEllipse(in: CGRect(x: wrappedX, y: py - h * 0.15, width: w * 0.4, height: h * 0.7))
        // Bolla destra bassa  
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.6, y: py - h * 0.12, width: w * 0.4, height: h * 0.72))
        // Bolla centrale superiore (fa la "gobba" principale)
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.3, y: py + h * 0.25, width: w * 0.4, height: h * 0.65))
        // Piccola bolla extra a sinistra
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.08, y: py + h * 0.05, width: w * 0.28, height: h * 0.5))
        // Piccola bolla extra a destra
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.65, y: py + h * 0.08, width: w * 0.3, height: h * 0.52))
        
        // Layer 3: Highlight sui bordi superiori (effetto luce dal sole)
        context.setFillColor(highlightColor)
        
        // Highlight sulla gobba principale
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.35, y: py + h * 0.45, width: w * 0.3, height: h * 0.35))
        // Piccoli highlight sulle bolle laterali
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.05, y: py + h * 0.15, width: w * 0.18, height: h * 0.28))
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.72, y: py + h * 0.18, width: w * 0.18, height: h * 0.28))
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
