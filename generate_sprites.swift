import Cocoa

let dir = "/Users/peppe/Desktop/PixelParallaxScreensaver/PixelParallax/Assets"
let fileManager = FileManager.default
if !fileManager.fileExists(atPath: dir) {
    try? fileManager.createDirectory(atPath: dir, withIntermediateDirectories: true, attributes: nil)
}

for i in 1...8 {
    let width = 16
    let height = 24
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
    
    // Clear transparent
    context.clear(CGRect(x: 0, y: 0, width: width, height: height))
    
    // Draw body
    context.setFillColor(NSColor.red.cgColor)
    context.fill(CGRect(x: 4, y: 8, width: 8, height: 10))
    
    // Draw head
    context.setFillColor(NSColor.blue.cgColor)
    context.fill(CGRect(x: 4, y: 18, width: 8, height: 6))
    
    // Draw legs animating
    context.setFillColor(NSColor.black.cgColor)
    if i % 2 == 0 {
        context.fill(CGRect(x: 4, y: 0, width: 3, height: 8)) // Left leg
        context.fill(CGRect(x: 9, y: 2, width: 3, height: 6)) // Right leg (lifted)
    } else {
        context.fill(CGRect(x: 4, y: 2, width: 3, height: 6)) // Left leg (lifted)
        context.fill(CGRect(x: 9, y: 0, width: 3, height: 8)) // Right leg
    }
    
    let cgImage = context.makeImage()!
    let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
    let pngData = bitmapRep.representation(using: .png, properties: [:])!
    let path = "\(dir)/hero_walk_\(i).png"
    try? pngData.write(to: URL(fileURLWithPath: path))
    print("Generated \(path)")
}
