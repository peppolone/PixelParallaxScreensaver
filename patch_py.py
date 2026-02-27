import os

with open("PixelParallax/MIScenery.swift", "r") as f:
    data = f.read()

start = data.find("    func drawPalms(context")
end = data.find("    // MARK: - Draw Fireflies")

if start != -1 and end != -1:
    new_content = """    func drawPalms(context: CGContext, bounds: CGRect, env: MIPalette.Environment) {
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
        
        let coconutColor = NSColor(hex: "#4E3629") ?? NSColor.brown
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
"""
    new_data = data[:start] + new_content + "\n" + data[end:]
    with open("PixelParallax/MIScenery.swift", "w") as f:
        f.write(new_data)
    print("Done!")
else:
    print(f"Failed. start: {start}, end: {end}")
