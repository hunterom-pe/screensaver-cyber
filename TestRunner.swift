import AppKit
import ScreenSaver
import WebKit

@main
class TestRunnerApp: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var saverView: CyberpunkSaverView!

    static func main() {
        let app = NSApplication.shared
        let delegate = TestRunnerApp()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 100, y: 100, width: 1280, height: 720),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CyberpunkSaver Live Host Diagnostic"
        window.center()
        
        saverView = CyberpunkSaverView(frame: window.contentView!.bounds, isPreview: false)
        if let saverView = saverView {
            saverView.autoresizingMask = [.width, .height]
            window.contentView?.addSubview(saverView)
            saverView.startAnimation()
        }
        
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        
        print("✅ CyberpunkSaver Host Window Started successfully!")
    }
}
