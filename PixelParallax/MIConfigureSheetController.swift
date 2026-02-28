import Cocoa
import ScreenSaver

class MIConfigureSheetController: NSObject {
    
    static let shared = MIConfigureSheetController()
    
    private var window: NSWindow?
    private var enableRainCheckbox: NSButton!
    private var enableCharactersCheckbox: NSButton!
    
    private var defaults: ScreenSaverDefaults? {
        let moduleIdentifier = Bundle(for: PixelParallaxView.self).bundleIdentifier ?? "com.peppolone.PixelParallax"
        return ScreenSaverDefaults(forModuleWithName: moduleIdentifier)
    }
    
    var isRainEnabled: Bool {
        get { return defaults?.bool(forKey: "EnableRain") ?? true }
        set { defaults?.set(newValue, forKey: "EnableRain"); defaults?.synchronize() }
    }
    
    var areCharactersEnabled: Bool {
        get { return defaults?.bool(forKey: "EnableCharacters") ?? true }
        set { defaults?.set(newValue, forKey: "EnableCharacters"); defaults?.synchronize() }
    }
    
    override init() {
        super.init()
        
        // Setup initial defaults if missing
        if defaults?.object(forKey: "EnableRain") == nil {
            defaults?.set(true, forKey: "EnableRain")
        }
        if defaults?.object(forKey: "EnableCharacters") == nil {
            defaults?.set(true, forKey: "EnableCharacters")
        }
        defaults?.synchronize()
    }
    
    func configureSheet() -> NSWindow {
        if let window = window {
            return window
        }
        
        let newWindow = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 300, height: 200),
                                 styleMask: [.titled],
                                 backing: .buffered,
                                 defer: false)
        newWindow.title = "PixelParallax Options"
        
        let contentView = NSView(frame: newWindow.contentRect(forFrameRect: newWindow.frame))
        
        let titleLabel = NSTextField(labelWithString: "PixelParallax Settings")
        titleLabel.font = NSFont.boldSystemFont(ofSize: 16)
        titleLabel.frame = NSRect(x: 20, y: 150, width: 260, height: 24)
        titleLabel.isBezeled = false
        titleLabel.drawsBackground = false
        titleLabel.isEditable = false
        titleLabel.isSelectable = false
        contentView.addSubview(titleLabel)
        
        enableRainCheckbox = NSButton(checkboxWithTitle: "Enable Dynamic Weather (Rain)", target: nil, action: nil)
        enableRainCheckbox.frame = NSRect(x: 20, y: 110, width: 260, height: 24)
        enableRainCheckbox.state = isRainEnabled ? .on : .off
        contentView.addSubview(enableRainCheckbox)
        
        enableCharactersCheckbox = NSButton(checkboxWithTitle: "Enable Characters on Beach", target: nil, action: nil)
        enableCharactersCheckbox.frame = NSRect(x: 20, y: 80, width: 260, height: 24)
        enableCharactersCheckbox.state = areCharactersEnabled ? .on : .off
        contentView.addSubview(enableCharactersCheckbox)
        
        let closeButton = NSButton(title: "OK", target: self, action: #selector(closeSheet))
        closeButton.frame = NSRect(x: 200, y: 20, width: 80, height: 32)
        // Make it the default button
        closeButton.keyEquivalent = "\r"
        contentView.addSubview(closeButton)
        
        newWindow.contentView = contentView
        self.window = newWindow
        
        return newWindow
    }
    
    @objc private func closeSheet() {
        // Save settings
        isRainEnabled = enableRainCheckbox.state == .on
        areCharactersEnabled = enableCharactersCheckbox.state == .on
        
        if let parent = window?.sheetParent {
            parent.endSheet(window!)
        } else {
            window?.close()
        }
    }
}
