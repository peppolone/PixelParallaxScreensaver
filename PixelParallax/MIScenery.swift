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
    private let isPreview: Bool
    
    private var shipX: CGFloat = -200
    private var boatYBob: CGFloat = 0
    private var shipRock: CGFloat = 0
    
    private var seaOffset: CGFloat = 0
    private var palmOffset: CGFloat = 0
    private var windStrength: CGFloat = 0
    private var bonfireX: CGFloat = 0
    
    // Beach height
    private let beachHeight: CGFloat = 0.12
    
    init(pixelSize: CGFloat, bounds: CGRect, isPreview: Bool = false) {
        self.pixelSize = pixelSize
        self.bounds = bounds
        self.isPreview = isPreview
        setupPalms(bounds: bounds)
        setupFireflies(bounds: bounds)
        shipX = bounds.width * 0.5
        bonfireX = bounds.width * 0.75
    }
    
    private func setupPalms(bounds: CGRect) {
        // In preview, mostra solo 2 palme invece di 7
        let backPalmCount = isPreview ? 1 : 4
        let frontPalmCount = isPreview ? 1 : 3
        
        for _ in 0..<backPalmCount {
            palms.append(MIPalm(
                x: CGFloat.random(in: 0...bounds.width),
                trunkHeight: CGFloat.random(in: 40...60),
                swayPhase: CGFloat.random(in: 0...6.28),
                swaySpeed: CGFloat.random(in: 1...2),
                scale: 0.7,
                layer: 0
            ))
        }
        for _ in 0..<frontPalmCount {
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
        // In preview, mostra solo 5 lucciole invece di 30
        let fireflyCount = isPreview ? 5 : 30
        
        for _ in 0..<fireflyCount {
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
        shipX += 0.2  // Movimento verso destra (era -0.2)
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
    
    // MARK: - Background Beach
    func drawBeachBackground(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        // La spiaggia viene disegnata tutta intera e in primo piano, per evitare linee dritte.
    }
        // MARK: - Monkey Island Silhouette
    func drawMonkeyIsland(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let horizonY = bounds.height * 0.35
        let islandWidth: CGFloat = bounds.width * 0.5
        let islandHeight: CGFloat = bounds.height * 0.25
        let islandX = bounds.width * 0.4
        
        let baseNightColor = NSColor(red: 0.05, green: 0.1, blue: 0.15, alpha: 1.0)
        let islandColor = env.skyBottom.nsColor.blended(withFraction: 0.7, of: baseNightColor) ?? .darkGray
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: islandX, y: horizonY))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.1, y: horizonY + islandHeight * 0.4))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.2, y: horizonY + islandHeight * 0.7))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.35, y: horizonY + islandHeight * 0.9))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.45, y: horizonY + islandHeight * 0.6))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.65, y: horizonY + islandHeight * 0.75))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.8, y: horizonY + islandHeight * 0.3))
        path.addLine(to: CGPoint(x: islandX + islandWidth, y: horizonY))
        path.closeSubpath()
        
        context.saveGState()
        context.setFillColor(islandColor.cgColor)
        context.addPath(path)
        context.fillPath()
        
        // Luci lontane
        let isDark = env.skyTop.r < 0.3 && env.skyTop.g < 0.3
        if isDark {
            let flicker = 0.5 + 0.5 * sin(time * 3.0)
            context.setFillColor(NSColor.systemYellow.withAlphaComponent(flicker).cgColor)
            context.fill(CGRect(x: islandX + islandWidth * 0.7, y: horizonY + islandHeight * 0.1, width: pixelSize*2, height: pixelSize*2))
        }
        context.restoreGState()
    }
    
    func drawMonkeyIslandReflection(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let horizonY = bounds.height * 0.35
        let islandWidth: CGFloat = bounds.width * 0.5
        let islandHeight: CGFloat = bounds.height * 0.25
        let islandX = bounds.width * 0.4
        
        let baseNightColor = NSColor(red: 0.05, green: 0.1, blue: 0.15, alpha: 1.0)
        let islandColor = env.skyBottom.nsColor.blended(withFraction: 0.7, of: baseNightColor) ?? .darkGray
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: islandX, y: horizonY))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.1, y: horizonY + islandHeight * 0.4))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.2, y: horizonY + islandHeight * 0.7))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.35, y: horizonY + islandHeight * 0.9))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.45, y: horizonY + islandHeight * 0.6))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.65, y: horizonY + islandHeight * 0.75))
        path.addLine(to: CGPoint(x: islandX + islandWidth * 0.8, y: horizonY + islandHeight * 0.3))
        path.addLine(to: CGPoint(x: islandX + islandWidth, y: horizonY))
        path.closeSubpath()
        
        context.saveGState()
        
        // CLIP BEFORE CTM FLIP
        context.clip(to: CGRect(x: 0, y: 0, width: bounds.width, height: horizonY))
        
        context.translateBy(x: 0, y: horizonY)
        context.scaleBy(x: 1.0, y: -0.6)
        
        var transform = CGAffineTransform.identity
        transform.c = 0.05 * sin(time * 2.0)
        context.concatenate(transform)
        
        context.translateBy(x: 0, y: -horizonY)
        
        let isDark = env.skyTop.r < 0.3 && env.skyTop.g < 0.3
        context.setAlpha(isDark ? 0.4 : 0.25)
        context.setFillColor(islandColor.cgColor)
        context.addPath(path)
        context.fillPath()
        
        context.restoreGState()
    }
        // MARK: - Draw Sea
    
    func drawSea(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let horizonY = bounds.height * 0.35
        
        let colors = [env.seaTop.nsColor.cgColor, env.seaBottom.nsColor.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: locations) {
            context.drawLinearGradient(gradient, start: CGPoint(x: 0, y: horizonY), end: CGPoint(x: 0, y: 0), options: [])
        }
        
        context.setFillColor(env.seaFoam.nsColor.withAlphaComponent(0.4).cgColor)
        let tileSize: CGFloat = pixelSize * 2
        let waveTime = time * 1.5
        
        for y in stride(from: CGFloat(0), through: horizonY, by: tileSize) {
            let rowFactor = y / horizonY
            let freq = 0.05 + rowFactor * 0.1
            let speed = 2.0 + rowFactor
            
            for x in stride(from: 0, through: bounds.width, by: tileSize) {
                let wave1 = sin(x * freq + waveTime * speed)
                let wave2 = cos(y * freq * 2.0 - waveTime + x * 0.02)
                let combinedWave = wave1 + wave2
                
                if combinedWave > 1.0 {
                    let intensity = min(1.0, (combinedWave - 1.0) * 1.5)
                    context.setFillColor(env.seaFoam.nsColor.withAlphaComponent(0.4 * intensity).cgColor)
                    context.fill(CGRect(x: x, y: y, width: pixelSize, height: pixelSize))
                    
                    if combinedWave > 1.6 && Int((x+y)) % 7 == 0 {
                        context.setFillColor(env.seaFoam.nsColor.withAlphaComponent(0.8).cgColor)
                        context.fill(CGRect(x: x + pixelSize, y: y, width: pixelSize, height: pixelSize))
                    }
                }
            }
        }
    }
    
    // MARK: - Sinuous Beach Foreground (Sabbia, onda riva, detriti)
    func drawSinuousBeachForeground(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let beachTop = bounds.height * beachHeight
        let sandDark = env.sand.nsColor.blended(withFraction: 0.3, of: .brown) ?? env.sand.nsColor
        let baseColor = env.sand.nsColor
        let sandDetail1 = sandDark.withAlphaComponent(0.4).cgColor
        let sandDetail2 = baseColor.blended(withFraction: 0.15, of: .black)?.withAlphaComponent(0.3).cgColor ?? sandDetail1
        let sandDetail3 = baseColor.blended(withFraction: 0.2, of: .white)?.withAlphaComponent(0.4).cgColor ?? sandDetail1
        
        context.saveGState()
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        
        // Disegna una forma della spiaggia che sale e scende gradualmente
        let steps = Int(bounds.width / 10.0)
        for i in 0...steps {
            let normX = CGFloat(i) / CGFloat(steps)
            let x = normX * bounds.width
            // curva asimmetrica: più alta a sinistra, scende verso il mare al centro e poi piccola ansa a destra
            let curve = sin(normX * .pi) * -(bounds.height * 0.04) + cos(normX * .pi * 2.5) * (bounds.height * 0.02)
            let shoreY = beachTop + curve + (1.0 - normX) * bounds.height * 0.04
            
            path.addLine(to: CGPoint(x: x, y: shoreY))
        }
        path.addLine(to: CGPoint(x: bounds.width, y: 0))
        path.closeSubpath()
        
        // Riempimento solido della spiaggia gialla
        context.addPath(path)
        context.setFillColor(baseColor.cgColor)
        context.fillPath()
        
        // Bordo scuro verso l'acqua (effetto pixel-art o bagnato)
        context.setStrokeColor(sandDark.cgColor)
        context.setLineWidth(pixelSize * 2)
        context.addPath(path)
        context.strokePath()
        
        // Clip per le particelle della sabbia
        context.addPath(path)
        context.clip()
        
        // Sabbia fine punteggiata
        let stepX = pixelSize * 6
        let stepY = pixelSize * 6
        for y in stride(from: CGFloat(0), to: beachTop * 1.5, by: stepY) {
            for x in stride(from: CGFloat(0), to: bounds.width, by: stepX) {
                let seed = Int(x * 13 + y * 7)
                if seed % 3 == 0 {
                    let drawX = x + CGFloat(seed % 5) * pixelSize
                    let drawY = y + CGFloat((seed / 5) % 5) * pixelSize
                    let colorRoll = seed % 3
                    if colorRoll == 0 { context.setFillColor(sandDetail1) }
                    else if colorRoll == 1 { context.setFillColor(sandDetail2) }
                    else { context.setFillColor(sandDetail3) }
                    let w = pixelSize * CGFloat((seed % 2) + 1)
                    context.fill(CGRect(x: drawX, y: drawY, width: w, height: pixelSize))
                }
            }
        }
        
        // Sassi decorativi sparsi
        for i in 0..<15 {
            let pseudoX = CGFloat((i * 12345) % Int(bounds.width))
            // NormX ricalcolata
            let normX = pseudoX / bounds.width
            let curve = sin(normX * .pi) * -(bounds.height * 0.04) + cos(normX * .pi * 2.5) * (bounds.height * 0.02)
            let maxShoreY = beachTop + curve + (1.0 - normX) * bounds.height * 0.04
            
            let pseudoY = CGFloat(2 + (i * 6789) % Int(max(1, maxShoreY * 0.6)))
            
            let elements = [NSColor.white, NSColor.darkGray, NSColor(red: 0.8, green: 0.6, blue: 0.4, alpha: 1.0)]
            let rockColor = elements[i % elements.count]
            
            context.setFillColor(sandDark.withAlphaComponent(0.8).cgColor)
            context.fill(CGRect(x: pseudoX, y: pseudoY - pixelSize, width: pixelSize * 2, height: pixelSize))
            context.setFillColor(rockColor.cgColor)
            context.fill(CGRect(x: pseudoX, y: pseudoY, width: pixelSize * CGFloat((i % 2) + 1), height: pixelSize))
            context.setFillColor(NSColor.white.withAlphaComponent(0.3).cgColor)
            context.fill(CGRect(x: pseudoX, y: pseudoY + pixelSize, width: pixelSize, height: pixelSize))
        }
        
        context.restoreGState()
    }
        // MARK: - Draw Ship
    
    /// Scala pixel per sprite (coerenza con MIBackground)
    private let spriteScale: CGFloat = 2.0
    
    func drawShip(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
        let horizonY = bounds.height * 0.35
        var drawX = shipX
        let wrap = bounds.width + 200
        while drawX < -150 { drawX += wrap }
        drawX = drawX.truncatingRemainder(dividingBy: wrap)
        
        let baseY = horizonY + boatYBob - 10
        
        context.saveGState()
        
        // Prova a caricare lo sprite della nave
        if let shipSprite = MISpriteLoader.shared.loadSprite(named: "ship") {
            // Disegna usando sprite
            let scaledWidth = CGFloat(shipSprite.width) * spriteScale
            let scaledHeight = CGFloat(shipSprite.height) * spriteScale
            
            // Posizione nave: sulla linea dell'orizzonte (acqua)
            let shipY = horizonY - scaledHeight/2 + boatYBob
            
            // Nave reale (disegna prima, così il riflesso va sotto)
            context.saveGState()
            context.translateBy(x: drawX + scaledWidth/2, y: shipY + scaledHeight/2)
            context.rotate(by: shipRock)
            context.translateBy(x: -(drawX + scaledWidth/2), y: -(shipY + scaledHeight/2))
            let shipRect = CGRect(x: drawX, y: shipY, width: scaledWidth, height: scaledHeight)
            context.draw(shipSprite, in: shipRect)
            context.restoreGState()
            
            // 🕯️ Lucine sulla nave di notte (calcoliamo se è buio dal colore del cielo)
            let isDark = env.skyTop.r < 0.3 && env.skyTop.g < 0.3
            if isDark {
                drawShipLights(context: context, shipX: drawX, shipY: shipY, 
                              shipWidth: scaledWidth, shipHeight: scaledHeight, isDark: isDark, alpha: 1.0)
            }
            
            // Reflection (riflesso nell'acqua, sotto la nave)
            context.saveGState()
            let beachTop = bounds.height * beachHeight
            // Riflesso: flippa verticalmente sotto la nave
            let reflectY = shipY - scaledHeight  // Sotto la nave
            context.clip(to: CGRect(x: 0, y: beachTop, width: bounds.width, height: horizonY - beachTop))
            context.setAlpha(0.25)
            // Flip verticale
            context.translateBy(x: 0, y: reflectY + scaledHeight)
            context.scaleBy(x: 1.0, y: -1.0)
            let reflectRect = CGRect(x: drawX, y: 0, width: scaledWidth, height: scaledHeight)
            context.draw(shipSprite, in: reflectRect)
            context.restoreGState()
            
            // Luci riflesse - disegnate FUORI dal contesto flippato
            if isDark {
                context.saveGState()
                context.clip(to: CGRect(x: 0, y: beachTop, width: bounds.width, height: horizonY - beachTop))
                // Le luci riflesse sono più in basso nell'acqua
                let reflectLightsY = shipY - scaledHeight * 1.2  // Più in basso
                drawShipLightsReflected(context: context, shipX: drawX, shipY: reflectLightsY, 
                              shipWidth: scaledWidth, shipHeight: scaledHeight, alpha: 0.2)
                context.restoreGState()
            }
        } else {
            // Fallback: disegno procedurale
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
        }
        
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
        
        let segs = 10
        let segH = palm.trunkHeight * scale / CGFloat(segs)
        var topX = x
        var topY = y
        
        context.setFillColor(env.palmTrunk.nsColor.cgColor)
        var currentY = y
        
        for i in 0..<segs {
            let curve = sin(CGFloat(i) * 0.2) * 10.0 * scale
            let segX = x + curve
            context.fill(CGRect(x: segX, y: currentY, width: 6*scale, height: segH))
            currentY += segH
            
            if i == segs - 1 {
                topX = segX + 3 * scale // center of trunk width
                topY = currentY
            }
        }
        
        context.translateBy(x: topX, y: topY)
        
        let coconutColor = NSColor(red: 78.0/255.0, green: 54.0/255.0, blue: 41.0/255.0, alpha: 1.0)
        context.setFillColor(coconutColor.cgColor)
        for c in 0..<3 {
            let cAngle = CGFloat(c) * 2.1 + 0.5
            let cDist = 4.0 * scale
            let cx = cos(cAngle) * cDist
            let cy = sin(cAngle) * cDist
            let r = 3.5 * scale
            context.fillEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        }
        
        let baseLeafColor = env.palmLeaf.nsColor
        let darkColorValue = baseLeafColor.blended(withFraction: 0.3, of: .black) ?? baseLeafColor
        let leafLen = 40.0 * scale
        
        for pass in 0..<2 {
            context.setFillColor(pass == 0 ? darkColorValue.cgColor : baseLeafColor.cgColor)
            
            let numLeaves = pass == 0 ? 5 : 4
            let angleOffset = pass == 1 ? 0.3 : 0.0
            
            for i in 0..<numLeaves {
                context.saveGState()
                
                let baseRotation = CGFloat(i) * (6.28 / CGFloat(numLeaves)) + angleOffset
                let windSway = sin(time + CGFloat(i)) * 0.15
                context.rotate(by: baseRotation + windSway)
                
                let leafPath = CGMutablePath()
                leafPath.move(to: .zero)
                leafPath.addQuadCurve(to: CGPoint(x: leafLen, y: -5 * scale),
                                      control: CGPoint(x: leafLen * 0.5, y: 15 * scale))
                
                var currentX = leafLen
                while currentX > 0 {
                    let pseudoRandom = CGFloat((i * 13 + pass * 7) % 10) / 10.0
                    let step = (3.0 + pseudoRandom * 3.0) * scale
                    currentX -= step
                    if currentX < 0 { currentX = 0 }
                    let drop = (2.0 + pseudoRandom * 3.0) * scale
                    
                    leafPath.addLine(to: CGPoint(x: currentX + step/2, y: -drop - 5 * scale))
                    leafPath.addLine(to: CGPoint(x: currentX, y: -2 * scale))
                }
                
                leafPath.addLine(to: .zero)
                leafPath.closeSubpath()
                
                context.addPath(leafPath)
                context.fillPath()
                context.restoreGState()
            }
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
    
    // MARK: - Ship Lights (Night)
    
    private func drawShipLights(context: CGContext, shipX: CGFloat, shipY: CGFloat, 
                                 shipWidth: CGFloat, shipHeight: CGFloat, isDark: Bool, alpha: CGFloat = 1.0) {
        // Posizioni relative delle luci sulla nave (in percentuale)
        let lightPositions: [(x: CGFloat, y: CGFloat)] = [
            (0.25, 0.3),   // Luce prua
            (0.5, 0.2),    // Luce albero maestro (bassa)
            (0.5, 0.7),    // Luce albero maestro (alta)
            (0.75, 0.25),  // Luce poppa
            (0.85, 0.4),   // Luce cabina
        ]
        
        // Colore luce calda (giallo/arancione)
        let baseColor = NSColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
        
        for (i, pos) in lightPositions.enumerated() {
            let lx = shipX + shipWidth * pos.x
            let ly = shipY + shipHeight * pos.y
            
            // Flicker effect (tremolio)
            let flicker = 0.7 + 0.3 * sin(time * 8.0 + CGFloat(i) * 2.5)
            let lightAlpha: CGFloat = (isDark ? flicker : flicker * 0.5) * alpha
            
            // Glow esterno (alone)
            context.saveGState()
            let glowRadius = pixelSize * 4
            let glowColor = baseColor.withAlphaComponent(lightAlpha * 0.3).cgColor
            context.setFillColor(glowColor)
            context.fillEllipse(in: CGRect(x: lx - glowRadius, y: ly - glowRadius, 
                                           width: glowRadius * 2, height: glowRadius * 2))
            context.restoreGState()
            
            // Luce centrale (pixel)
            context.setFillColor(baseColor.withAlphaComponent(lightAlpha).cgColor)
            context.fill(CGRect(x: lx - pixelSize/2, y: ly - pixelSize/2, 
                                width: pixelSize, height: pixelSize))
        }
    }
    
    // Luci riflesse nell'acqua (Y invertita)
    private func drawShipLightsReflected(context: CGContext, shipX: CGFloat, shipY: CGFloat, 
                                 shipWidth: CGFloat, shipHeight: CGFloat, alpha: CGFloat) {
        let lightPositions: [(x: CGFloat, y: CGFloat)] = [
            (0.25, 0.7),   // Luce prua (invertita: 1-0.3)
            (0.5, 0.8),    // Luce albero maestro bassa (invertita: 1-0.2)
            (0.5, 0.3),    // Luce albero maestro alta (invertita: 1-0.7)
            (0.75, 0.75),  // Luce poppa (invertita: 1-0.25)
            (0.85, 0.6),   // Luce cabina (invertita: 1-0.4)
        ]
        
        let baseColor = NSColor(red: 1.0, green: 0.8, blue: 0.3, alpha: 1.0)
        
        for (i, pos) in lightPositions.enumerated() {
            let lx = shipX + shipWidth * pos.x
            let ly = shipY + shipHeight * pos.y
            
            let flicker = 0.7 + 0.3 * sin(time * 8.0 + CGFloat(i) * 2.5)
            let lightAlpha: CGFloat = flicker * alpha
            
            // Solo il glow per il riflesso (più sfumato)
            let glowRadius = pixelSize * 5
            let glowColor = baseColor.withAlphaComponent(lightAlpha * 0.4).cgColor
            context.setFillColor(glowColor)
            context.fillEllipse(in: CGRect(x: lx - glowRadius, y: ly - glowRadius, 
                                           width: glowRadius * 2, height: glowRadius * 2))
        }
    }
}
