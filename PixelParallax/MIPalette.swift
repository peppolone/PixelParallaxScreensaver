import Cocoa

struct MIColor {
    let r: CGFloat
    let g: CGFloat
    let b: CGFloat
    let a: CGFloat
    
    var nsColor: NSColor {
        return NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
    }
    
    static func fromHex(_ hex: Int, alpha: CGFloat = 1.0) -> MIColor {
        let r = CGFloat((hex >> 16) & 0xFF) / 255.0
        let g = CGFloat((hex >> 8) & 0xFF) / 255.0
        let b = CGFloat(hex & 0xFF) / 255.0
        return MIColor(r: r, g: g, b: b, a: alpha)
    }
    
    static func lerp(start: MIColor, end: MIColor, t: CGFloat) -> MIColor {
        let clampedT = max(0, min(1, t))
        return MIColor(
            r: start.r + (end.r - start.r) * clampedT,
            g: start.g + (end.g - start.g) * clampedT,
            b: start.b + (end.b - start.b) * clampedT,
            a: start.a + (end.a - start.a) * clampedT
        )
    }
}

struct MIPalette {
    
    // MARK: - Dynamic Environment System
    struct Environment {
        let skyTop: MIColor
        let skyBottom: MIColor
        let sunMoon: MIColor
        let sunMoonGlow: MIColor
        let seaTop: MIColor
        let seaBottom: MIColor
        let seaFoam: MIColor
        let sand: MIColor
        let distantIsland: MIColor
        let cloudColor: MIColor
        let palmTrunk: MIColor
        let palmLeaf: MIColor
    }
    
    // Presets
    static let envDay = Environment(
        skyTop: MIColor.fromHex(0x4FA4B8),
        skyBottom: MIColor.fromHex(0xB8F5FF),
        sunMoon: MIColor.fromHex(0xFFF6D3),
        sunMoonGlow: MIColor.fromHex(0xFFEF9E, alpha: 0.5),
        seaTop: MIColor.fromHex(0x2E6D94),
        seaBottom: MIColor.fromHex(0x1A4766),
        seaFoam: MIColor.fromHex(0xFFFFFF),
        sand: MIColor.fromHex(0xE6C288),
        distantIsland: MIColor.fromHex(0x5D8E9C),
        cloudColor: MIColor.fromHex(0xFFFFFF, alpha: 0.8),
        palmTrunk: MIColor.fromHex(0x8B5A2B),
        palmLeaf: MIColor.fromHex(0x6DAA2C)
    )
    
    static let envSunset = Environment(
        skyTop: MIColor.fromHex(0x563868),
        skyBottom: MIColor.fromHex(0xFF9E5E),
        sunMoon: MIColor.fromHex(0xFFD66A),
        sunMoonGlow: MIColor.fromHex(0xFF7B52, alpha: 0.6),
        seaTop: MIColor.fromHex(0x4A3B69),
        seaBottom: MIColor.fromHex(0x2D2145),
        seaFoam: MIColor.fromHex(0xFFCCAA),
        sand: MIColor.fromHex(0xBA8C70),
        distantIsland: MIColor.fromHex(0x6B4C69),
        cloudColor: MIColor.fromHex(0xFFCC99, alpha: 0.7),
        palmTrunk: MIColor.fromHex(0x5C3A1E),
        palmLeaf: MIColor.fromHex(0x556B2F)
    )
    
    static let envNight = Environment(
        skyTop: MIColor.fromHex(0x050510),
        skyBottom: MIColor.fromHex(0x101035),
        sunMoon: MIColor.fromHex(0xFFFFFF),
        sunMoonGlow: MIColor.fromHex(0x444499, alpha: 0.4),
        seaTop: MIColor.fromHex(0x0A0A25),
        seaBottom: MIColor.fromHex(0x02020A),
        seaFoam: MIColor.fromHex(0x222266),
        sand: MIColor.fromHex(0x151525),
        distantIsland: MIColor.fromHex(0x050510),
        cloudColor: MIColor.fromHex(0x202040, alpha: 0.3),
        palmTrunk: MIColor.fromHex(0x111111),
        palmLeaf: MIColor.fromHex(0x112211)
    )
    
    static func interpolate(from: Environment, to: Environment, t: CGFloat) -> Environment {
        return Environment(
            skyTop: MIColor.lerp(start: from.skyTop, end: to.skyTop, t: t),
            skyBottom: MIColor.lerp(start: from.skyBottom, end: to.skyBottom, t: t),
            sunMoon: MIColor.lerp(start: from.sunMoon, end: to.sunMoon, t: t),
            sunMoonGlow: MIColor.lerp(start: from.sunMoonGlow, end: to.sunMoonGlow, t: t),
            seaTop: MIColor.lerp(start: from.seaTop, end: to.seaTop, t: t),
            seaBottom: MIColor.lerp(start: from.seaBottom, end: to.seaBottom, t: t),
            seaFoam: MIColor.lerp(start: from.seaFoam, end: to.seaFoam, t: t),
            sand: MIColor.lerp(start: from.sand, end: to.sand, t: t),
            distantIsland: MIColor.lerp(start: from.distantIsland, end: to.distantIsland, t: t),
            cloudColor: MIColor.lerp(start: from.cloudColor, end: to.cloudColor, t: t),
            palmTrunk: MIColor.lerp(start: from.palmTrunk, end: to.palmTrunk, t: t),
            palmLeaf: MIColor.lerp(start: from.palmLeaf, end: to.palmLeaf, t: t)
        )
    }
    
    // MARK: - Static Character Colors (Legacy Support)
    // Guybrush
    static let guybrushHairLight = NSColor(calibratedRed: 0.95, green: 0.80, blue: 0.45, alpha: 1.0)
    static let guybrushHairMid = NSColor(calibratedRed: 0.85, green: 0.68, blue: 0.35, alpha: 1.0)
    static let guybrushHairDark = NSColor(calibratedRed: 0.75, green: 0.55, blue: 0.25, alpha: 1.0)
    static let guybrushSkin = NSColor(calibratedRed: 0.95, green: 0.80, blue: 0.68, alpha: 1.0)
    static let guybrushSkinShadow = NSColor(calibratedRed: 0.80, green: 0.60, blue: 0.50, alpha: 1.0)
    static let guybrushShirt = NSColor(calibratedRed: 0.98, green: 0.98, blue: 0.95, alpha: 1.0)
    static let guybrushShirtShadow = NSColor(calibratedRed: 0.78, green: 0.78, blue: 0.82, alpha: 1.0)
    static let guybrushPants = NSColor(calibratedRed: 0.35, green: 0.28, blue: 0.55, alpha: 1.0)
    static let guybrushPantsDark = NSColor(calibratedRed: 0.22, green: 0.18, blue: 0.40, alpha: 1.0)
    static let guybrushBoots = NSColor(calibratedRed: 0.30, green: 0.22, blue: 0.15, alpha: 1.0)

    // LeChuck
    static let lechuckGlow = NSColor(calibratedRed: 0.28, green: 0.65, blue: 0.38, alpha: 1.0)
    static let lechuckGlowDim = NSColor(calibratedRed: 0.20, green: 0.50, blue: 0.28, alpha: 0.6)
    static let lechuckSkin = NSColor(calibratedRed: 0.35, green: 0.55, blue: 0.40, alpha: 1.0)
    static let lechuckSkinDark = NSColor(calibratedRed: 0.25, green: 0.42, blue: 0.30, alpha: 1.0)
    static let lechuckBeard = NSColor(calibratedRed: 0.15, green: 0.35, blue: 0.22, alpha: 1.0)
    static let lechuckBeardDark = NSColor(calibratedRed: 0.08, green: 0.22, blue: 0.12, alpha: 1.0)
    static let lechuckCoat = NSColor(calibratedRed: 0.25, green: 0.12, blue: 0.12, alpha: 1.0)
    static let lechuckHat = NSColor(calibratedRed: 0.15, green: 0.08, blue: 0.08, alpha: 1.0)
    
    // Monkey
    static let monkeyFur = NSColor(calibratedRed: 0.55, green: 0.38, blue: 0.22, alpha: 1.0)
    static let monkeySkin = NSColor(calibratedRed: 0.75, green: 0.60, blue: 0.45, alpha: 1.0)
    
    // Ship (Static fallbacks)
    static let shipWood = NSColor(calibratedRed: 0.42, green: 0.30, blue: 0.18, alpha: 1.0)
    static let sailWhite = NSColor(calibratedRed: 0.88, green: 0.85, blue: 0.78, alpha: 1.0)
    static let sailRed = NSColor(calibratedRed: 0.65, green: 0.20, blue: 0.18, alpha: 1.0)
    
    // Generic
    static let white = NSColor.white
    static let black = NSColor.black
    static let clear = NSColor.clear
    
    // MARK: - Legacy Character Colors (Restored for Compatibility)
    static let moonMid = NSColor(white: 0.9, alpha: 1.0)
    
    // Skeleton / Murray
    static let boneLight = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.85, alpha: 1.0)
    static let boneMid = NSColor(calibratedRed: 0.7, green: 0.7, blue: 0.65, alpha: 1.0)
    static let boneSocket = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
    static let murrayBone = boneLight
    static let murrayBoneShadow = boneMid
    static let murrayEyeGlow = NSColor(calibratedRed: 1.0, green: 0.3, blue: 0.1, alpha: 1.0)
    static let murrayEyeCore = NSColor(calibratedRed: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
    
    // Monkey
    static let monkeyFurLight = NSColor(calibratedRed: 0.65, green: 0.48, blue: 0.32, alpha: 1.0)
    static let monkeyFurDark = NSColor(calibratedRed: 0.40, green: 0.25, blue: 0.10, alpha: 1.0)
    static let monkeyFace = NSColor(calibratedRed: 0.85, green: 0.70, blue: 0.60, alpha: 1.0)
    static let monkeyNose = NSColor(calibratedRed: 0.2, green: 0.1, blue: 0.05, alpha: 1.0)
    
    // Parrot
    static let parrotRed = NSColor(calibratedRed: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    static let parrotRedDark = NSColor(calibratedRed: 0.6, green: 0.1, blue: 0.1, alpha: 1.0)
    static let parrotBlue = NSColor(calibratedRed: 0.2, green: 0.2, blue: 0.9, alpha: 1.0)
    static let parrotBlueDark = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.6, alpha: 1.0)
    static let parrotGreen = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0.2, alpha: 1.0)
    static let parrotYellow = NSColor(calibratedRed: 0.9, green: 0.9, blue: 0.2, alpha: 1.0)
    
    // Mermaid
    static let mermaidTailLight = NSColor(calibratedRed: 0.3, green: 0.8, blue: 0.6, alpha: 1.0)
    static let mermaidTailDark = NSColor(calibratedRed: 0.1, green: 0.5, blue: 0.4, alpha: 1.0)
    static let mermaidScales = NSColor(calibratedRed: 0.4, green: 0.9, blue: 0.7, alpha: 1.0)
    static let mermaidSkin = NSColor(calibratedRed: 0.95, green: 0.80, blue: 0.70, alpha: 1.0)
    static let mermaidSkinShadow = NSColor(calibratedRed: 0.80, green: 0.65, blue: 0.55, alpha: 1.0)
    static let mermaidHair = NSColor(calibratedRed: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
    static let mermaidHairDark = NSColor(calibratedRed: 0.5, green: 0.1, blue: 0.1, alpha: 1.0)
    static let mermaidShell = NSColor(calibratedRed: 0.8, green: 0.5, blue: 0.8, alpha: 1.0)

    // Stan
    static let stanJacketCheck1 = NSColor(calibratedRed: 0.8, green: 0.2, blue: 0.8, alpha: 1.0)
    static let stanJacketCheck2 = NSColor(calibratedRed: 0.2, green: 0.8, blue: 0.8, alpha: 1.0)
    static let stanSkin = NSColor(calibratedRed: 0.95, green: 0.75, blue: 0.60, alpha: 1.0)
    static let stanHair = NSColor(calibratedRed: 0.1, green: 0.1, blue: 0.4, alpha: 1.0)
    
    // Speech Bubble
    static let speechBubble = NSColor.white
    static let speechBorder = NSColor.black
    
    // Forgotten Colors
    static let lechuckEyes = NSColor(calibratedRed: 0.9, green: 0.2, blue: 0.2, alpha: 1.0)
    static let seaLight = NSColor(calibratedRed: 0.2, green: 0.4, blue: 0.7, alpha: 1.0) // Legacy
}
