import Foundation
import AppKit
import SwiftUI

class CustomMainWindow: NSWindow {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        // Let an attached editor sheet handle Escape / Command-W itself.
        if attachedSheet != nil { return super.performKeyEquivalent(with: event) }
        // 支持 Command + W 关闭窗口
        if event.modifierFlags.intersection([.command, .control, .option, .shift]) == .command {
            if let chars = event.charactersIgnoringModifiers, chars.lowercased() == "w" {
                self.performClose(nil)
                return true
            }
        }
        // 支持 ESC 键关闭窗口
        if event.keyCode == 53 {
            self.performClose(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
}

public class MainWindowController: NSObject, NSWindowDelegate {
    public static let shared = MainWindowController()
    private var window: CustomMainWindow?

    public func showWindow(tab: DeckTab = .appSwitcher) {
        if let win = window {
            win.contentView = NSHostingView(rootView: MainContainerView(initialTab: tab))
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let newWindow = CustomMainWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        newWindow.title = "Deck"
        newWindow.titleVisibility = .hidden
        newWindow.titlebarAppearsTransparent = true
        newWindow.isOpaque = true
        newWindow.backgroundColor = NSColor(red: 0.980, green: 0.983, blue: 0.988, alpha: 1.0)
        newWindow.contentMinSize = NSSize(width: 900, height: 560)
        newWindow.center()
        newWindow.isReleasedWhenClosed = false
        newWindow.delegate = self
        applyAppearance(to: newWindow)
        newWindow.contentView = NSHostingView(rootView: MainContainerView(initialTab: tab))

        self.window = newWindow
        newWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func updateAppearance() {
        if let win = window {
            applyAppearance(to: win)
        }
    }

    private func applyAppearance(to win: NSWindow) {
        switch ConfigStore.shared.config.themeMode {
        case .light:
            win.appearance = NSAppearance(named: .aqua)
        case .dark:
            win.appearance = NSAppearance(named: .darkAqua)
        case .system:
            win.appearance = nil
        }
    }

    public func close() {
        window?.close()
    }

    public func windowWillClose(_ notification: Notification) {
        window = nil
    }
}
