import Cocoa
import ScreenSaver

/// Thread-safe sprite loading helper for pixel art assets using Swift Actors
/// 
/// ## Come aggiungere nuovi sprite:
/// 
/// 1. Crea il tuo sprite con un editor grafico (Aseprite, Pixaki, Photoshop, GIMP)
/// 2. Esporta come PNG (con trasparenza se necessario)
/// 3. Copia il file PNG in: PixelParallax/Assets/
/// 4. In Xcode: trascina il file nella cartella del progetto
/// 5. Assicurati che "Copy items if needed" sia selezionato
/// 6. Assicurati che sia aggiunto al target "PixelParallax"
/// 
/// ## Struttura consigliata per sprite sheets:
/// - character_walk_1.png, character_walk_2.png, ... per animazioni
/// - palm_small.png, palm_large.png per varianti
/// - bonfire_1.png, bonfire_2.png, ... per animazione fuoco
///
/// ## Thread Safety:
/// Questo è un Actor, quindi tutte le operazioni sono automaticamente thread-safe.
/// Usa `await` per accedere ai metodi o la versione sincrona per il main thread.
///
actor MISpriteLoaderActor {
    
    private var cachedImages: [String: CGImage] = [:]
    private let bundle: Bundle
    
    init() {
        // Get the bundle that contains the screensaver
        // Try multiple identifiers for compatibility
        if let bundle = Bundle(identifier: "com.peppe.PixelParallax") {
            self.bundle = bundle
        } else if let bundle = Bundle(identifier: "com.screensaver.PixelParallax") {
            self.bundle = bundle
        } else {
            self.bundle = Bundle.main
        }
    }
    
    /// Carica uno sprite PNG dalla cartella Resources del bundle (async version)
    /// - Parameter name: nome del file senza estensione (es: "character_walk_1")
    /// - Returns: CGImage se trovato, nil altrimenti
    func loadSprite(named name: String) -> CGImage? {
        // Check cache first
        if let cached = cachedImages[name] {
            return cached
        }
        
        // Try to load from bundle
        guard let url = bundle.url(forResource: name, withExtension: "png") else {
            NSLog("MISpriteLoader: Sprite '\(name).png' not found in bundle")
            return nil
        }
        
        guard let dataProvider = CGDataProvider(url: url as CFURL) else {
            NSLog("MISpriteLoader: Could not create data provider for '\(name).png'")
            return nil
        }
        
        guard let image = CGImage(pngDataProviderSource: dataProvider, 
                                   decode: nil, 
                                   shouldInterpolate: false, 
                                   intent: .defaultIntent) else {
            NSLog("MISpriteLoader: Could not decode PNG for '\(name).png'")
            return nil
        }
        
        // Cache for future use
        cachedImages[name] = image
        NSLog("MISpriteLoader: Loaded sprite '\(name).png' (\(image.width)x\(image.height))")
        
        return image
    }
    
    /// Carica una serie di frame per animazioni
    /// - Parameters:
    ///   - baseName: nome base (es: "character_walk")
    ///   - frameCount: numero di frame (es: 4 caricherà _1, _2, _3, _4)
    /// - Returns: Array di CGImage
    func loadAnimation(baseName: String, frameCount: Int) -> [CGImage] {
        var frames: [CGImage] = []
        for i in 1...frameCount {
            if let frame = loadSprite(named: "\(baseName)_\(i)") {
                frames.append(frame)
            }
        }
        return frames
    }
    
    /// Pulisce la cache (utile per liberare memoria)
    func clearCache() {
        cachedImages.removeAll()
        NSLog("MISpriteLoader: Cache cleared")
    }
    
    /// Numero di sprite in cache
    var cachedCount: Int {
        cachedImages.count
    }
}

// MARK: - Synchronous Wrapper for Main Thread Usage

/// Wrapper sincrono per l'uso sul main thread
/// NOTA: Usare SOLO dal main thread per evitare data races
class MISpriteLoader {
    
    static let shared = MISpriteLoader()
    
    private var cachedImages: [String: CGImage] = [:]
    private let bundle: Bundle
    
    private init() {
        // Get the bundle that contains the screensaver
        // Try multiple identifiers for compatibility
        if let bundle = Bundle(identifier: "com.peppe.PixelParallax") {
            self.bundle = bundle
            NSLog("MISpriteLoader: Using bundle com.peppe.PixelParallax")
        } else if let bundle = Bundle(identifier: "com.screensaver.PixelParallax") {
            self.bundle = bundle
            NSLog("MISpriteLoader: Using bundle com.screensaver.PixelParallax")
        } else {
            self.bundle = Bundle.main
            NSLog("MISpriteLoader: Using Bundle.main")
        }
    }
    
    /// Carica uno sprite PNG dalla cartella Resources del bundle
    /// - Parameter name: nome del file senza estensione (es: "character_walk_1")
    /// - Returns: CGImage se trovato, nil altrimenti
    func loadSprite(named name: String) -> CGImage? {
        // Per retrocompatibilità, uso diretto senza async
        // Sicuro perché chiamato solo dal main thread nel contesto screensaver
        return loadSpriteSync(named: name)
    }
    
    private func loadSpriteSync(named name: String) -> CGImage? {
        // Use instance bundle (already resolved in init)
        // Try to load from bundle
        guard let url = bundle.url(forResource: name, withExtension: "png") else {
            NSLog("MISpriteLoader: Sprite '\(name).png' not found in bundle \(bundle.bundleIdentifier ?? "unknown")")
            return nil
        }
        
        guard let dataProvider = CGDataProvider(url: url as CFURL) else {
            NSLog("MISpriteLoader: Could not create data provider for '\(name).png'")
            return nil
        }
        
        guard let image = CGImage(pngDataProviderSource: dataProvider, 
                                   decode: nil, 
                                   shouldInterpolate: false, 
                                   intent: .defaultIntent) else {
            NSLog("MISpriteLoader: Could not decode PNG for '\(name).png'")
            return nil
        }
        
        NSLog("MISpriteLoader: Loaded sprite '\(name).png' (\(image.width)x\(image.height))")
        return image
    }
    
    /// Carica una serie di frame per animazioni
    func loadAnimation(baseName: String, frameCount: Int) -> [CGImage] {
        var frames: [CGImage] = []
        for i in 1...frameCount {
            if let frame = loadSprite(named: "\(baseName)_\(i)") {
                frames.append(frame)
            }
        }
        return frames
    }
    
    /// Disegna uno sprite nel context con scaling pixel-perfect
    /// - Parameters:
    ///   - image: CGImage da disegnare
    ///   - context: CGContext dove disegnare
    ///   - x: coordinata X
    ///   - y: coordinata Y
    ///   - scale: fattore di scala (1.0 = dimensione originale, 2.0 = 2x, etc.)
    ///   - flipX: se true, specchia orizzontalmente
    static func drawSprite(_ image: CGImage, 
                          in context: CGContext, 
                          at x: CGFloat, 
                          y: CGFloat, 
                          scale: CGFloat = 1.0,
                          flipX: Bool = false) {
        let width = CGFloat(image.width) * scale
        let height = CGFloat(image.height) * scale
        
        context.saveGState()
        
        // Disable interpolation for pixel-perfect rendering
        context.interpolationQuality = .none
        context.setShouldAntialias(false)
        
        if flipX {
            context.translateBy(x: x + width, y: y)
            context.scaleBy(x: -1.0, y: 1.0)
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        } else {
            context.draw(image, in: CGRect(x: x, y: y, width: width, height: height))
        }
        
        context.restoreGState()
    }
}

// MARK: - Esempio di uso con sprite sheets

/*
 
 === GUIDA PER AGGIUNGERE SPRITE PERSONALIZZATI ===
 
 1. CREA GLI SPRITE
    - Usa Aseprite (https://www.aseprite.org) - il migliore per pixel art
    - Oppure Pixaki, Photoshop, GIMP, Piskel (gratuito online)
    - Dimensioni consigliate per personaggi: 16x24, 24x32, 32x48 pixel
    - Salva con trasparenza PNG
 
 2. NOMINA I FILE
    - character_idle_1.png, character_idle_2.png (per animazioni)
    - character_walk_1.png, character_walk_2.png, character_walk_3.png, character_walk_4.png
    - palm_1.png, palm_2.png (per varianti)
    - bonfire_1.png, bonfire_2.png, bonfire_3.png (per animazione fuoco)
 
 3. AGGIUNGI AL PROGETTO
    - Copia i PNG nella cartella: PixelParallax/Assets/
    - Apri il progetto in Xcode
    - Trascina i file dal Finder nella sidebar di Xcode sotto il gruppo "PixelParallax"
    - Nella finestra di dialogo:
      ✓ "Copy items if needed"
      ✓ "Create folder references" (opzionale)
      ✓ Add to targets: PixelParallax
 
 4. USA NEL CODICE
 
    // Carica singolo sprite
    if let palmImage = MISpriteLoader.shared.loadSprite(named: "palm_1") {
        MISpriteLoader.drawSprite(palmImage, in: context, at: x, y: y, scale: 3.0)
    }
    
    // Carica animazione
    let walkFrames = MISpriteLoader.shared.loadAnimation(baseName: "character_walk", frameCount: 4)
    let frameIndex = Int(time * 10) % walkFrames.count
    if frameIndex < walkFrames.count {
        MISpriteLoader.drawSprite(walkFrames[frameIndex], in: context, at: x, y: y, scale: 3.0, flipX: direction < 0)
    }
 
 5. STRUMENTI CONSIGLIATI
    - Aseprite: $20, il gold standard per pixel art
    - Piskel: gratuito, online (https://www.piskelapp.com)
    - Pixilart: gratuito, online (https://www.pixilart.com)
    - GIMP: gratuito, desktop
    - Photoshop: se già lo hai
 
 6. PALETTE CONSIGLIATE
    - Cerca su https://lospec.com/palette-list
    - Palette classiche: PICO-8, Endesga 32, DB32
 
 */
