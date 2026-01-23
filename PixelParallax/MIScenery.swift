import Cocoa

struct MIPalm: Sendable {
    var x: CGFloat
    var trunkHeight: CGFloat
    var swayPhase: CGFloat
    var swaySpeed: CGFloat
    var scale: CGFloat
    var layer: Int
}

struct MIFirefly: Sendable {
    var x: CGFloat
    var y: CGFloat
    var phase: CGFloat
    var speed: CGFloat
    var wanderX: CGFloat = 0
    var wanderY: CGFloat = 0
}

struct MIParticle: Sendable {
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var life: CGFloat
    var maxLife: CGFloat
    var type: Int
}

/// Gestisce scenari: palme, mare, nave, falò e particelle
/// NOTA: Questa classe deve essere usata solo dal main thread
class MIScenery {
    
    private var palms: [MIPalm] = []
    private var fireflies: [MIFirefly] = []
    private var fireParticles: [MIParticle] = []
    
    let pixelSize: CGFloat
    private var time: CGFloat = 0
    private var bounds: CGRect = .zero
    
    private var shipX: CGFloat = 0
    private var boatYBob: CGFloat = 0
    private var shipRock: CGFloat = 0
    
    private var seaOffset: CGFloat = 0
    private var palmOffset: CGFloat = 0
    private var windStrength: CGFloat = 0
    private var bonfireX: CGFloat = 0
    
    // Beach height
    private let beachHeight: CGFloat = 0.12
    
    init(pixelSize: CGFloat, bounds: CGRect) {
        self.pixelSize = pixelSize
        self.bounds = bounds
        setupPalms(bounds: bounds)
        setupFireflies(bounds: bounds)
        shipX = bounds.width * 0.5
        bonfireX = bounds.width * 0.75
    }
    
    private func setupPalms(bounds: CGRect) {
        for _ in 0..<4 {
            palms.append(MIPalm(
                x: CGFloat.random(in: 0...bounds.width),
                trunkHeight: CGFloat.random(in: 40...60),
                swayPhase: CGFloat.random(in: 0...6.28),
                swaySpeed: CGFloat.random(in: 1...2),
                scale: 0.7,
                layer: 0
            ))
        }
        for _ in 0..<3 {
            palms.append(MIPalm(
                x: CGFloat.random(in: 0...bounds.width),
                trunkHeight: CGFloat.random(in: 80...120),
                swayPhase: CGFloat.random(in: 0...6.28),
                swaySpeed: CGFloat.random(in: 2...3),
                scale: 1.0,
                layer: 1
            ))
        }
    }
    
    private func setupFireflies(bounds: CGRect) {
        for _ in 0..<30 {
            fireflies.append(MIFirefly(
                x: CGFloat.random(in: 0...bounds.width),
                y: CGFloat.random(in: 0...bounds.height * 0.5),
                phase: CGFloat.random(in: 0...6.28),
                speed: CGFloat.random(in: 2...5)
            ))
        }
    }
    
    func update(deltaTime: CGFloat) {
        time += deltaTime
        seaOffset += 0.15
        palmOffset += 0.12
        shipX -= 0.2
        boatYBob = sin(time * 1.5) * 2.0
        shipRock = sin(time * 0.8) * 0.05
        windStrength = sin(time * 0.5) * 0.2
        
        for i in 0..<fireflies.count {
            fireflies[i].wanderX = sin(time * fireflies[i].speed + fireflies[i].phase) * 20
            fireflies[i].wanderY = cos(time * fireflies[i].speed * 0.8) * 15
        }
        
        // Fire particles
        for _ in 0..<2 {
            fireParticles.append(MIParticle(
                x: bonfireX + CGFloat.random(in: -5...5) * pixelSize,
                y: 50,
                vx: CGFloat.random(in: -0.5...0.5) * pixelSize,
                vy: CGFloat.random(in: 1...3) * pixelSize,
                life: 1.0,
                maxLife: CGFloat.random(in: 0.5...1.0),
                type: 0
            ))
        }
        
        // Smoke particles
        if Int.random(in: 0...10) == 0 {
            fireParticles.append(MIParticle(
                x: bonfireX + CGFloat.random(in: -3...3) * pixelSize,
                y: 80,
                vx: CGFloat.random(in: -1...1) * pixelSize + (windStrength * 5),
                vy: CGFloat.random(in: 0.5...1.5) * pixelSize,
                life: 1.0,
                maxLife: CGFloat.random(in: 2.0...4.0),
                type: 1
            ))
        }
        
        for i in (0..<fireParticles.count).reversed() {
            fireParticles[i].x += fireParticles[i].vx
            fireParticles[i].y += fireParticles[i].vy
            fireParticles[i].life -= deltaTime / fireParticles[i].maxLife
            fireParticles[i].x += sin(time * 10 + CGFloat(i)) * 0.5
            
            if fireParticles[i].life <= 0 {
                fireParticles.remove(at: i)
            }
        }
    }
    
    // MARK: - Draw Beach (before sea for proper layering)
    
    func drawBeach(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let beachTop = bounds.height * beachHeight
        
        // Sand gradient
        let sandDark = env.sand.nsColor.blended(withFraction: 0.3, of: .brown) ?? env.sand.nsColor
        let colors = [sandDark.cgColor, env.sand.nsColor.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: beachTop), options: [])
        }
        
        // Sand texture pixels
        context.setFillColor(sandDark.withAlphaComponent(0.3).cgColor)
        for _ in 0..<40 {
            let x = CGFloat.random(in: 0...bounds.width)
            let y = CGFloat.random(in: 0...beachTop)
            context.fill(CGRect(x: x, y: y, width: pixelSize, height: pixelSize))
        }
        
        // Some shells/pebbles on beach
        context.setFillColor(NSColor.white.withAlphaComponent(0.5).cgColor)
        for _ in 0..<10 {
            let x = CGFloat.random(in: 0...bounds.width)
            let y = CGFloat.random(in: 2...beachTop * 0.8)
            context.fill(CGRect(x: x, y: y, width: pixelSize, height: pixelSize))
        }
    }
    
    // MARK: - Draw Sea
    
    func drawSea(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let beachTop = bounds.height * beachHeight
        let horizonY = bounds.height * 0.35
        
        // Sea gradient from beach to horizon
        let colors = [env.seaTop.nsColor.cgColor, env.seaBottom.nsColor.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: horizonY), end: CGPoint(x: 0, y: beachTop), options: [])
        }
        
        // Wave foam
        context.setFillColor(env.seaFoam.nsColor.withAlphaComponent(0.4).cgColor)
        let tileSize: CGFloat = pixelSize * 2
        
        for y in stride(from: beachTop, through: horizonY, by: tileSize) {
            let rowFactor = (y - beachTop) / (horizonY - beachTop)
            let freq = 0.05 + rowFactor * 0.1
            let speed = 2.0 + rowFactor
            
            for x in stride(from: 0, through: bounds.width, by: tileSize) {
                let wave = sin(x * freq + time * speed) + cos(y * freq * 2.0 - time)
                if wave > 1.2 {
                    context.fill(CGRect(x: x, y: y, width: pixelSize, height: pixelSize))
                }
            }
        }
        
        // Shoreline foam
        context.setFillColor(env.seaFoam.nsColor.withAlphaComponent(0.7).cgColor)
        for x in stride(from: 0, through: bounds.width, by: pixelSize * 3) {
            let waveOffset = sin(x * 0.05 + time * 2) * pixelSize * 2
            context.fill(CGRect(x: x, y: beachTop + waveOffset, width: pixelSize * 2, height: pixelSize))
        }
    }
    
    // MARK: - Draw Ship
    
    func drawShip(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let horizonY = bounds.height * 0.35
        var drawX = shipX
        let wrap = bounds.width + 200
        while drawX < -150 { drawX += wrap }
        drawX = drawX.truncatingRemainder(dividingBy: wrap)
        
        let baseY = horizonY + boatYBob - 10
        
        context.saveGState()
        
        // Reflection
        context.saveGState()
        let beachTop = bounds.height * beachHeight
        context.translateBy(x: 0, y: horizonY)
        context.scaleBy(x: 1.0, y: -1.0)
        context.translateBy(x: 0, y: -horizonY)
        context.clip(to: CGRect(x: 0, y: beachTop, width: bounds.width, height: horizonY - beachTop))
        
        var transform = CGAffineTransform.identity
        transform.c = 0.1 * sin(time * 2.0)
        context.concatenate(transform)
        context.setAlpha(0.3)
        drawShipHull(context: context, x: drawX, y: baseY, env: env, reflection: true)
        context.restoreGState()
        
        // Actual ship
        drawShipHull(context: context, x: drawX, y: baseY, env: env, reflection: false)
        
        context.restoreGState()
    }
    
    private func drawShipHull(context: CGContext, x: CGFloat, y: CGFloat, env: MIPalette.Environment, reflection: Bool) {
        let scale = pixelSize
        
        context.saveGState()
        context.translateBy(x: x + 60*scale, y: y)
        context.rotate(by: shipRock)
        context.translateBy(x: -(x + 60*scale), y: -y)
        
        // Hull
        context.setFillColor(env.palmTrunk.nsColor.cgColor)
        let hullPath = CGMutablePath()
        hullPath.move(to: CGPoint(x: x, y: y + 25*scale))
        hullPath.addLine(to: CGPoint(x: x, y: y + 10*scale))
        hullPath.addCurve(to: CGPoint(x: x + 40*scale, y: y - 5*scale), control1: CGPoint(x: x, y: y), control2: CGPoint(x: x + 10*scale, y: y - 5*scale))
        hullPath.addLine(to: CGPoint(x: x + 100*scale, y: y - 5*scale))
        hullPath.addCurve(to: CGPoint(x: x + 130*scale, y: y + 20*scale), control1: CGPoint(x: x + 120*scale, y: y - 5*scale), control2: CGPoint(x: x + 130*scale, y: y + 5*scale))
        hullPath.addLine(to: CGPoint(x: x, y: y + 25*scale))
        hullPath.closeSubpath()
        context.addPath(hullPath)
        context.fillPath()
        
        // Hull stripe
        let darkerBrown = env.palmTrunk.nsColor.blended(withFraction: 0.3, of: .black) ?? env.palmTrunk.nsColor
        context.setFillColor(darkerBrown.cgColor)
        context.fill(CGRect(x: x, y: y + 22*scale, width: 125*scale, height: 3*scale))
        
        // Masts
        context.fill(CGRect(x: x + 60*scale, y: y + 25*scale, width: 4*scale, height: 70*scale))
        context.fill(CGRect(x: x + 100*scale, y: y + 20*scale, width: 3*scale, height: 50*scale))
        
        // Bowsprit
        context.saveGState()
        context.translateBy(x: x + 130*scale, y: y + 20*scale)
        context.rotate(by: -0.5)
        context.fill(CGRect(x: 0, y: 0, width: 30*scale, height: 3*scale))
        context.restoreGState()
        
        // Sails
        context.setFillColor(env.cloudColor.nsColor.withAlphaComponent(0.95).cgColor)
        
        let windCurve = sin(time) * 5 * scale
        let sailPath = CGMutablePath()
        let msX = x + 35*scale
        let msY = y + 45*scale
        sailPath.move(to: CGPoint(x: msX, y: msY))
        sailPath.addLine(to: CGPoint(x: msX + 50*scale, y: msY))
        sailPath.addQuadCurve(to: CGPoint(x: msX, y: msY - 20*scale), control: CGPoint(x: msX + 25*scale + windCurve, y: msY - 30*scale))
        context.addPath(sailPath)
        context.fillPath()
        
        let jibPath = CGMutablePath()
        jibPath.move(to: CGPoint(x: x + 100*scale, y: y + 60*scale))
        jibPath.addLine(to: CGPoint(x: x + 100*scale, y: y + 30*scale))
        jibPath.addLine(to: CGPoint(x: x + 150*scale, y: y + 40*scale))
        context.addPath(jibPath)
        context.fillPath()
        
        // Flag
        if !reflection {
            context.setFillColor(NSColor.red.cgColor)
            let flagX = x + 62*scale
            let flagY = y + 95*scale
            let flagW = 15*scale
            let flap = sin(time * 5) * 3 * scale
            let flagPath = CGMutablePath()
            flagPath.move(to: CGPoint(x: flagX, y: flagY))
            flagPath.addLine(to: CGPoint(x: flagX + flagW, y: flagY + flap))
            flagPath.addLine(to: CGPoint(x: flagX + flagW - 5*scale, y: flagY - 8*scale + flap))
            flagPath.addLine(to: CGPoint(x: flagX, y: flagY - 8*scale))
            context.addPath(flagPath)
            context.fillPath()
        }
        
        context.restoreGState()
    }
    
    // MARK: - Draw Bonfire (on the beach)
    
    func drawBonfire(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let bx = bonfireX
        let fireBaseY = bounds.height * beachHeight * 0.5  // Middle of beach
        
        // Logs
        context.setFillColor(NSColor.brown.cgColor)
        context.saveGState()
        context.translateBy(x: bx, y: fireBaseY)
        context.fill(CGRect(x: -15, y: 0, width: 30, height: 6))
        context.rotate(by: 0.3)
        context.fill(CGRect(x: -15, y: 0, width: 30, height: 6))
        context.rotate(by: -0.6)
        context.fill(CGRect(x: -15, y: 0, width: 30, height: 6))
        context.restoreGState()
        
        // Fire particles
        for p in fireParticles {
            let drawX = p.x
            let drawY = fireBaseY + (p.y - 50)
            let alpha = max(0, min(1, p.life))
            
            if p.type == 0 {
                // Fire colors based on life
                if p.life > 0.7 {
                    context.setFillColor(NSColor.yellow.withAlphaComponent(alpha).cgColor)
                } else if p.life > 0.4 {
                    context.setFillColor(NSColor.orange.withAlphaComponent(alpha).cgColor)
                } else {
                    context.setFillColor(NSColor.red.withAlphaComponent(alpha).cgColor)
                }
                let size = pixelSize * (p.life * 2 + 1)
                context.fill(CGRect(x: drawX - size/2, y: drawY - size/2, width: size, height: size))
            } else {
                // Smoke
                context.setFillColor(NSColor.gray.withAlphaComponent(alpha * 0.5).cgColor)
                let size = pixelSize * (4 - p.life * 2)
                context.fill(CGRect(x: drawX - size/2, y: drawY - size/2, width: size, height: size))
            }
        }
        
        // Glow effect
        context.saveGState()
        context.setBlendMode(.screen)
        let flick = CGFloat.random(in: 0.8...1.0)
        let glowColor = NSColor.orange.withAlphaComponent(0.15 * flick)
        context.setFillColor(glowColor.cgColor)
        context.fillEllipse(in: CGRect(x: bx - 60, y: fireBaseY - 10, width: 120, height: 80))
        context.restoreGState()
    }
    
    // MARK: - Draw Palms
    
    func drawPalms(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let beachTop = bounds.height * beachHeight
        
        for palm in palms {
            var drawX = palm.x
            if palm.layer == 0 {
                drawX -= palmOffset
            }
            let wrap = bounds.width + 200
            while drawX < -100 { drawX += wrap }
            drawX = drawX.truncatingRemainder(dividingBy: wrap)
            
            drawSinglePalm(context: context, x: drawX, y: beachTop * 0.3, palm: palm, env: env)
        }
    }
    
    private func drawSinglePalm(context: CGContext, x: CGFloat, y: CGFloat, palm: MIPalm, env: MIPalette.Environment) {
        context.saveGState()
        let scale = palm.scale * pixelSize
        
        // Trunk
        context.setFillColor(env.palmTrunk.nsColor.cgColor)
        let tx = x
        var ty = y
        let segs = 10
        let segH = palm.trunkHeight * scale / CGFloat(segs)
        
        for i in 0..<segs {
            let curve = sin(CGFloat(i) * 0.2) * 10.0 * scale
            context.fill(CGRect(x: tx + curve, y: ty, width: 6*scale, height: segH))
            ty += segH
        }
        
        // Leaves
        let topCurve = sin(CGFloat(segs) * 0.2) * 10.0 * scale
        context.translateBy(x: tx + topCurve + 3*scale, y: ty)
        
        let shear = windStrength * (palm.layer == 1 ? 1.5 : 1.0)
        let transform = CGAffineTransform(a: 1, b: 0, c: shear, d: 1, tx: 0, ty: 0)
        context.concatenate(transform)
        
        context.setFillColor(env.palmLeaf.nsColor.cgColor)
        let leafLen = 40.0 * scale
        
        for i in 0..<5 {
            context.saveGState()
            context.rotate(by: CGFloat(i) * (6.28 / 5.0) + sin(time + CGFloat(i)) * 0.2)
            context.fillEllipse(in: CGRect(x: 0, y: -2*scale, width: leafLen, height: 4*scale))
            context.restoreGState()
        }
        
        context.restoreGState()
    }
    
    // MARK: - Draw Fireflies
    
    func drawFireflies(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        context.setFillColor(MIPalette.guybrushSkin.withAlphaComponent(0.8).cgColor)
        
        for ff in fireflies {
            let dx = ff.x + ff.wanderX
            let dy = ff.y + ff.wanderY
            let px = round(dx / pixelSize) * pixelSize
            let py = round(dy / pixelSize) * pixelSize
            context.fill(CGRect(x: px, y: py, width: pixelSize, height: pixelSize))
        }
    }
}
