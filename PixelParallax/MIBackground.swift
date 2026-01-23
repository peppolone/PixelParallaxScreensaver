import Cocoa
import ScreenSaver

struct MIStar {
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var twinklePhase: CGFloat
    var twinkleSpeed: CGFloat
}

struct MICloud {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var type: Int
    var speed: CGFloat
}

class MIBackground {
    
    private var stars: [MIStar] = []
    private var cloudsBack: [MICloud] = []
    private var cloudsFront: [MICloud] = []
    
    private var starOffset: CGFloat = 0
    private var mountainOffset: CGFloat = 0
    
    let pixelSize: CGFloat
    private var time: CGFloat = 0
    
    init(pixelSize: CGFloat, bounds: CGRect) {
        self.pixelSize = pixelSize
        generateStars(bounds: bounds)
        generateClouds(bounds: bounds)
    }
    
    private func generateStars(bounds: CGRect) {
        for _ in 0..<150 {
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
        for _ in 0..<5 {
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
        
        context.setFillColor(env.cloudColor.nsColor.cgColor)
        
        let py = cloud.y
        let w = cloud.width
        let h = w * 0.4
        
        context.fillEllipse(in: CGRect(x: wrappedX, y: py, width: w * 0.6, height: h))
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.3, y: py + h * 0.2, width: w * 0.7, height: h * 0.8))
        context.fillEllipse(in: CGRect(x: wrappedX + w * 0.2, y: py - h * 0.2, width: w * 0.5, height: h * 0.9))
    }
}
