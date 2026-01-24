import Cocoa

/// Struttura per un personaggio animato
/// Puoi aggiungere i tuoi personaggi creati con Aseprite
struct MIPixelCharacter: Sendable {
    var x: CGFloat
    var z: CGFloat          // Profondità (più grande = più vicino)
    var speed: CGFloat
    var direction: CGFloat  // 1.0 = destra, -1.0 = sinistra
    var walkPhase: CGFloat
    var spriteType: String  // Nome del tipo di sprite (es: "hero", "npc1")
}

/// Gestisce i personaggi animati sulla spiaggia
/// Per aggiungere personaggi:
/// 1. Crea sprite in Aseprite (es: hero_walk_1.png, hero_walk_2.png, ...)
/// 2. Aggiungi i PNG in PixelParallax/Assets/
/// 3. Aggiungi il tipo in characterSprites
class MICharacters {
    
    private var characters: [MIPixelCharacter] = []
    private let pixelSize: CGFloat
    private let isPreview: Bool
    
    /// Dizionario di sprite per ogni tipo di personaggio
    /// Chiave: nome tipo, Valore: Array di frame animazione CGImage
    private var characterSprites: [String: [CGImage]] = [:]
    
    init(pixelSize: CGFloat, bounds: CGRect, isPreview: Bool = false) {
        self.pixelSize = pixelSize
        self.isPreview = isPreview
        loadSprites()
        setupCharacters(bounds: bounds)
    }
    
    /// Carica gli sprite dalla cartella Assets
    /// Cerca file con pattern: {tipo}_walk_{numero}.png
    private func loadSprites() {
        // Esempio: per caricare sprite "hero", metti in Assets:
        // hero_walk_1.png, hero_walk_2.png, hero_walk_3.png, etc.
        
        let spriteTypes = ["hero", "villager", "npc"]  // Aggiungi qui i tuoi tipi
        
        for spriteType in spriteTypes {
            var frames: [CGImage] = []
            
            // Prova a caricare fino a 8 frame per tipo
            for i in 1...8 {
                let spriteName = "\(spriteType)_walk_\(i)"
                if let sprite = MISpriteLoader.shared.loadSprite(named: spriteName) {
                    frames.append(sprite)
                }
            }
            
            if !frames.isEmpty {
                characterSprites[spriteType] = frames
                NSLog("MICharacters: Loaded \(frames.count) frames for \(spriteType)")
            }
        }
    }
    
    /// Configura i personaggi iniziali
    private func setupCharacters(bounds: CGRect) {
        // Per ora nessun personaggio - aggiungi i tuoi qui!
        // Quando avrai creato sprite in Aseprite, decommenta e modifica:
        
        /*
        // Esempio: aggiungi un eroe
        if characterSprites["hero"] != nil {
            characters.append(MIPixelCharacter(
                x: bounds.width * 0.3,
                z: 1.0,
                speed: 20.0,
                direction: 1.0,
                walkPhase: 0,
                spriteType: "hero"
            ))
        }
        */
    }
    
    /// Chiamato ogni frame per aggiornare posizioni
    func update(deltaTime: CGFloat, bounds: CGRect) {
        for i in 0..<characters.count {
            let moveSpeed = characters[i].speed * characters[i].z
            characters[i].x += moveSpeed * characters[i].direction * deltaTime
            characters[i].walkPhase += deltaTime * 8.0
            
            // Wrap around ai bordi
            let margin: CGFloat = 80.0
            if characters[i].direction > 0 && characters[i].x > bounds.width + margin {
                characters[i].x = -margin
            } else if characters[i].direction < 0 && characters[i].x < -margin {
                characters[i].x = bounds.width + margin
            }
        }
    }
    
    /// Disegna tutti i personaggi
    func drawAll(context: CGContext, bounds: CGRect) {
        let beachY = bounds.height * 0.08
        
        for character in characters {
            if let frames = characterSprites[character.spriteType], !frames.isEmpty {
                drawCharacterSprite(context: context, character: character, frames: frames, baseY: beachY)
            }
        }
    }
    
    /// Disegna un singolo personaggio usando sprite
    private func drawCharacterSprite(context: CGContext, character: MIPixelCharacter, frames: [CGImage], baseY: CGFloat) {
        let frameIndex = Int(character.walkPhase) % frames.count
        let sprite = frames[frameIndex]
        
        let scale = pixelSize * character.z * 0.8
        let yDepthOffset = (1.2 - character.z) * 30 * pixelSize
        let yPos = baseY + yDepthOffset
        
        // Bobbing verticale per simulare camminata
        let bobPhase = Int(character.walkPhase * 2) % 4
        let bobY = (bobPhase == 1 || bobPhase == 3) ? scale * 0.3 : 0
        
        MISpriteLoader.drawSprite(
            sprite, 
            in: context, 
            at: character.x, 
            y: yPos + bobY, 
            scale: scale, 
            flipX: character.direction < 0
        )
    }
}
