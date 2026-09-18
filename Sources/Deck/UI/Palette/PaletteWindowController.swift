import Foundation
import AppKit
import SwiftUI

class CustomPalettePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

public class PaletteWindowController: NSObject {
    public static let shared = PaletteWindowController()

    private var panel: CustomPalettePanel?
    private var localKeyMonitor: Any?
    private var globalMouseMonitor: Any?

    public var isVisible: Bool {
        panel?.isVisible ?? false
    }

    public override init() {
        super.init()
    }

    private func setupPanel() {
        if panel != nil { return }

        let customPanel = CustomPalettePanel(
            contentRect: NSRect(x: 0, y: 0, width: 310, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        customPanel.isOpaque = false
        customPanel.backgroundColor = .clear
        customPanel.hasShadow = true
        customPanel.level = .popUpMenu // 高层级，保证浮在任何应用（包括全屏）之上
        customPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        customPanel.isMovableByWindowBackground = true

        let rootView = PaletteView(
            onItemTriggered: { [weak self] item in
                self?.hidePalette()
                AppSwitcher.shared.execute(item: item)
            },
            onClose: { [weak self] in
                self?.hidePalette()
            },
            onOpenSettings: { [weak self] in
                self?.hidePalette()
                MainWindowController.shared.showWindow(tab: .appSwitcher)
            }
        )

        let hostingView = NSHostingView(rootView: rootView)
        customPanel.contentView = hostingView

        self.panel = customPanel
    }

    /// 切换浮窗显示/隐藏
    public func toggle() {
        if isVisible {
            hidePalette()
        } else {
            showPalette()
        }
    }

    /// 显示浮窗
    public func showPalette() {
        setupPanel()
        guard let panel = panel else { return }

        panel.contentView?.layoutSubtreeIfNeeded()

        // 确定展示的目标屏幕
        let mouseLocation = NSEvent.mouseLocation
        let targetScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens.first

        if let screen = targetScreen {
            let screenFrame = screen.visibleFrame
            let windowSize = panel.frame.size

            var originX: CGFloat
            var originY: CGFloat

            if ConfigStore.shared.config.showAtCursor {
                originX = mouseLocation.x - (windowSize.width / 2)
                originY = mouseLocation.y - (windowSize.height / 2)

                originX = max(screenFrame.minX + 10, min(originX, screenFrame.maxX - windowSize.width - 10))
                originY = max(screenFrame.minY + 10, min(originY, screenFrame.maxY - windowSize.height - 10))
            } else {
                originX = screenFrame.minX + (screenFrame.width - windowSize.width) / 2
                originY = screenFrame.minY + (screenFrame.height - windowSize.height) / 2
            }

            panel.setFrameOrigin(NSPoint(x: originX, y: originY))
        }

        // 激活应用并使窗口成为关键窗口
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.12
            panel.animator().alphaValue = 1.0
        }

        // 添加本地键盘监听（瞬时响应按键）
        installMonitors()
    }

    /// 隐藏浮窗
    public func hidePalette() {
        guard let panel = panel, panel.isVisible else { return }

        removeMonitors()

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.1
            panel.animator().alphaValue = 0.0
        }, completionHandler: {
            panel.orderOut(nil)
            panel.alphaValue = 1.0
        })
    }

    private func installMonitors() {
        removeMonitors()

        // 监听本地键盘事件
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, self.isVisible else { return event }

            // 按下 ESC 键
            if event.keyCode == 53 {
                self.hidePalette()
                return nil
            }

            // 匹配配置的快捷键
            if let chars = event.characters, !chars.isEmpty {
                let pressed = chars.lowercased()
                let items = ConfigStore.shared.config.items

                if let matched = items.first(where: {
                    $0.key == chars || $0.key.lowercased() == pressed
                }) {
                    self.hidePalette()
                    AppSwitcher.shared.execute(item: matched)
                    return nil
                }
            }

            return event
        }

        // 监听全局鼠标点击：点击外部时自动隐藏
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, self.isVisible else { return }
            let clickLocation = NSEvent.mouseLocation
            if !NSMouseInRect(clickLocation, panel.frame, false) {
                DispatchQueue.main.async {
                    self.hidePalette()
                }
            }
        }
    }

    private func removeMonitors() {
        if let monitor = localKeyMonitor {
            NSEvent.removeMonitor(monitor)
            localKeyMonitor = nil
        }
        if let monitor = globalMouseMonitor {
            NSEvent.removeMonitor(monitor)
            globalMouseMonitor = nil
        }
    }
}
