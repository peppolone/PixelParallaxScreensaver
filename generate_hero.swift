import Cocoa

let dir = "/Users/peppe/Desktop/PixelParallaxScreensaver/PixelParallax/Assets"

// Guybrush-like colors
let skin = NSColor(red: 245/255.0, green: 189/255.0, blue: 142/255.0, alpha: 1.0).cgColor
let shirt = NSColor(red: 230/255.0, green: 230/255.0, blue: 230/255.0, alpha: 1.0).cgColor
let coat = NSColor(red: 70/255.0, green: 70/255.0, blue: 150/255.0, alpha: 1.0).cgColor
let pants = NSColor(red: 120/255.0, green: 100/255.0, blue: 80/255.0, alpha: 1.0).cgColor
let boots = NSColor(red: 40/255.0, green: 30/255.0, blue: 30/255.0, alpha: 1.0).cgColor
let hair = NSColor(red: 255/255.0, green: 220/255.0, blue: 100/255.0, alpha: 1.0).cgColor

for i in 1...8 {
    let width = 24
    let height = 36
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    
    // Antialiasing off for pixel art
    context.setShouldAntialias(false)
    context.clear(CGRect(x: 0, y: 0, width: width, height: height))
    
    let f = CGFloat(i)
    let frames = 8.0
    let bob: CGFloat = (i % 4 == 1 || i % 4 == 0) ? -1 : 0
    let cx: CGFloat = 12
    let cy: CGFloat = 10 + bob
    
    // Fill helpers
    func fillRect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ c: CGColor) {
        context.setFillColor(c)
        let rectY = CGFloat(height) - y - h
        context.fill(CGRect(x: x, y: rectY, width: w, height: h))
    }
    
    // Hair
    fillRect(cx - 3, cy - 4, 7, 4, hair)
    // Face
    fillRect(cx - 2, cy - 1, 5, 5, skin)
    // Coat
    fillRect(cx - 4, cy + 4, 7, 10, coat)
    // Shirt
    fillRect(cx - 1, cy + 4, 3, 10, shirt)
    
    // Arms
    let armSwing = round(sin(f / frames * .pi * 2) * 4)
    fillRect(cx + 1 + armSwing, cy + 5, 2, 7, coat) // Right arm
    fillRect(cx + 1 + armSwing, cy + 12, 2, 2, skin) // Right hand
    
    fillRect(cx - 3 - armSwing, cy + 5, 2, 7, coat) // Left arm
    fillRect(cx - 3 - armSwing, cy + 12, 2, 2, skin) // Left hand
    
    // Legs
    let legSwing = round(sin(f / frames * .pi * 2) * 5)
    fillRect(cx + 0 + legSwing, cy + 14, 3, 8, pants) // Right leg
    fillRect(cx - 1 + legSwing, cy + 22, 4, 2, boots) // Right boot
    
    fillRect(cx - 2 - legSwing, cy + 14, 3, 8, pants) // Left leg
    fillRect(cx - 3 - legSwing, cy + 22, 4, 2, boots) // Left boot
    
    let cgImage = context.makeImage()!
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    let pngData = bitmapRep.representation(using: .png, properties: [:])!
    try? pngData.write(to: URL(fileURLWithPath: "\(dir)/hero_walk_\(i).png"))
}
print("Generated hero frames")
