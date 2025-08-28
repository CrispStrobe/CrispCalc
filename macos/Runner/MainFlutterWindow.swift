/// macos/Runner/MainFlutterWindow.swift

import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    // --- FIX: Set an ideal initial window size and a minimum size ---
    // This ensures the app opens at a good size and can't be shrunk too small.
    let screenRect = NSScreen.main?.frame ?? .zero
    let initialFrame = NSRect(
        x: (screenRect.width - 450) / 2, // Center the window horizontally
        y: (screenRect.height - 750) / 2, // Center the window vertically
        width: 450,
        height: 750
    )
    self.setFrame(initialFrame, display: true)
    
    // Set a minimum size to prevent the UI from breaking.
    self.minSize = NSSize(width: 420, height: 650)
    // --- End of Fix ---

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}