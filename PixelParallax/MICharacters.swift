import Cocoa

fileprivate struct NPCColors {
    static let skin = NSColor(calibratedRed: 0.94, green: 0.82, blue: 0.69, alpha: 1.0)
    static let hair = NSColor(calibratedRed: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
}

/// Tipo di personaggio NPC
enum NPCType: String, CaseIterable {
    case character1 = "character"    // NPC generico
    case guybrush = "guybrush"       // Guybrush Threepwood
    case lechuck = "lechuck"         // LeChuck
    case murray = "murray"           // Murray il teschio
}

struct MIPixelCharacter: Sendable {
    var x: CGFloat
    var z: CGFloat
    var speed: CGFloat
    var direction: CGFloat
    var walkPhase: CGFloat
    var colorShirt: NSColor
    var colorPants: NSColor
    var npcType: NPCType
}

/// Gestisce i personaggi NPC animati sulla spiaggia
/// NOTA: Questa classe deve essere usata solo dal main thread
class MICharacters {
    
    private var npcs: [MIPixelCharacter] = []
    private let pixelSize: CGFloat
    
    /// Dizionario di sprite per ogni tipo di NPC
    /// Chiave: NPCType, Valore: Array di frame animazione
    private var npcSprites: [NPCType: [CGImage]] = [:]
    
    init(pixelSize: CGFloat, bounds: CGRect) {
        self.pixelSize = pixelSize
        loadSprites()
        setupNPCs(bounds: bounds)
    }
    
    private func loadSprites() {
        // Per ogni tipo di NPC, prova a caricare i suoi frame di animazione
        for npcType in NPCType.allCases {
            var frames: [CGImage] = []
            
            // Prova a caricare fino a 8 frame per tipo
            for i in 1...8 {
                let spriteName = "\(npcType.rawValue)_walk_\(i)"
                if let sprite = MISpriteLoader.shared.loadSprite(named: spriteName) {
                    frames.append(sprite)
                }
            }
            
            if !frames.isEmpty {
                npcSprites[npcType] = frames
                NSLog("MICharacters: Loaded \(frames.count) frames for \(npcType.rawValue)")
            }
        }
        
        NSLog("MICharacters: Total NPC types with sprites: \(npcSprites.count)")
    }
    
    private func setupNPCs(bounds: CGRect) {
        // Crea NPC per ogni tipo che ha sprite, oppure usa character1 come fallback
        let availableTypes = npcSprites.isEmpty ? [NPCType.character1] : Array(npcSprites.keys)
        
        for i in 0..<3 {
            let npcType = availableTypes[i % availableTypes.count]
            
            npcs.append(MIPixelCharacter(
                x: CGFloat.random(in: 0...bounds.width),
                z: CGFloat.random(in: 0.8...1.2),
                speed: CGFloat.random(in: 15...25),
                direction: Bool.random() ? 1.0 : -1.0,
                walkPhase: CGFloat.random(in: 0...10),
                colorShirt: Bool.random() ? .white : NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.8, alpha: 1),
                colorPants: Bool.random() ? NSColor.brown : NSColor.darkGray,
                npcType: npcType
            ))
        }
    }
    
    func update(deltaTime: CGFloat, bounds: CGRect) {
        for i in 0..<npcs.count {
            let moveSpeed = npcs[i].speed * npcs[i].z
            npcs[i].x += moveSpeed * npcs[i].direction * deltaTime
            npcs[i].walkPhase += deltaTime * 8.0
            let margin: CGFloat = 80.0
            if npcs[i].direction > 0 && npcs[i].x > bounds.width + margin {
                npcs[i].x = -margin
            } else if npcs[i].direction < 0 && npcs[i].x < -margin {
                npcs[i].x = bounds.width + margin
            }
        }
    }
    
    func drawAll(context: CGContext, bounds: CGRect) {
        let beachY = bounds.height * 0.08
        for npc in npcs {
            // Usa sprite se disponibili per questo tipo di NPC
            if let frames = npcSprites[npc.npcType], !frames.isEmpty {
                drawCharacterSprite(context: context, npc: npc, frames: frames, baseY: beachY)
            } else {
                drawCharacterProcedural(context: context, npc: npc, baseY: beachY)
            }
        }
    }
    
    private func drawCharacterSprite(context: CGContext, npc: MIPixelCharacter, frames: [CGImage], baseY: CGFloat) {
        // Cicla tra tutti i frame disponibili basandosi su walkPhase
        let frameIndex = Int(npc.walkPhase) % frames.count
        let sprite = frames[frameIndex]
        
        let scale = pixelSize * npc.z * 3.0
        let yDepthOffset = (1.2 - npc.z) * 30 * pixelSize
        let yPos = baseY + yDepthOffset
        
        // Bobbing verticale per simulare movimento camminata
        let bobPhase = Int(npc.walkPhase * 2) % 4
        let bobY = (bobPhase == 1 || bobPhase == 3) ? scale * 0.5 : 0
        
        MISpriteLoader.drawSprite(sprite, in: context, at: npc.x, y: yPos + bobY, scale: scale, flipX: npc.direction < 0)
    }
    
    private func drawCharacterProcedural(context: CGContext, npc: MIPixelCharacter, baseY: CGFloat) {
        context.saveGState()
        let scale = pixelSize * npc.z
        let yDepthOffset = (1.2 - npc.z) * 30 * pixelSize
        let yPos = baseY + yDepthOffset
        context.translateBy(x: npc.x, y: yPos)
        if npc.direction < 0 {
            context.scaleBy(x: -1.0, y: 1.0)
            context.translateBy(x: -scale*5, y: 0)
        }
        let frame = Int(npc.walkPhase) % 4
        let bobY = (frame == 1 || frame == 3) ? scale : 0
        context.setFillColor(NPCColors.skin.cgColor)
        context.fill(CGRect(x: 1*scale, y: 10*scale + bobY, width: 3*scale, height: 3*scale))
        context.setFillColor(NPCColors.hair.cgColor)
        context.fill(CGRect(x: 1*scale, y: 12*scale + bobY, width: 3*scale, height: 1*scale))
        context.fill(CGRect(x: 1*scale, y: 11*scale + bobY, width: 1*scale, height: 2*scale))
        context.setFillColor(npc.colorShirt.cgColor)
        context.fill(CGRect(x: 0*scale, y: 6*scale + bobY, width: 5*scale, height: 4*scale))
        if frame == 0 || frame == 2 {
            context.fill(CGRect(x: 1*scale, y: 5*scale + bobY, width: 1*scale, height: 2*scale))
            context.fill(CGRect(x: 3*scale, y: 5*scale + bobY, width: 1*scale, height: 2*scale))
        } else {
            context.fill(CGRect(x: 0*scale, y: 6*scale + bobY, width: 1*scale, height: 2*scale))
            context.fill(CGRect(x: 4*scale, y: 6*scale + bobY, width: 1*scale, height: 2*scale))
        }
        context.setFillColor(npc.colorPants.cgColor)
        context.fill(CGRect(x: 1*scale, y: 3*scale + bobY, width: 3*scale, height: 3*scale))
        context.setFillColor(NSColor.black.cgColor)
        switch frame {
        case 0, 2:
            context.fill(CGRect(x: 1*scale, y: 0*scale, width: 1*scale, height: 3*scale + bobY))
            context.fill(CGRect(x: 3*scale, y: 0*scale, width: 1*scale, height: 3*scale + bobY))
        case 1:
            context.fill(CGRect(x: 1*scale, y: 0*scale, width: 1*scale, height: 3*scale + bobY))
            context.fill(CGRect(x: 4*scale, y: 1*scale + bobY, width: 1*scale, height: 2*scale))
        case 3:
            context.fill(CGRect(x: 0*scale, y: 1*scale + bobY, width: 1*scale, height: 2*scale))
            context.fill(CGRect(x: 3*scale, y: 0*scale, width: 1*scale, height: 3*scale + bobY))
        default: break
        }
        context.restoreGState()
    }
}
