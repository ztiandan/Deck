import Foundation
import AppKit

public class MenuBarManager: NSObject, NSMenuDelegate {
    public static let shared = MenuBarManager()

    private var statusItem: NSStatusItem?

    public func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = Self.createDeckMenuBarIcon()
            button.toolTip = loc(.menuTooltip)
        }

        let menu = NSMenu()
        menu.delegate = self
        statusItem?.menu = menu
        rebuildMenu()
    }

    public func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    public func rebuildMenu() {
        guard let menu = statusItem?.menu else { return }
        menu.removeAllItems()

        if let button = statusItem?.button {
            button.toolTip = loc(.menuTooltip)
        }

        let hostsStore = HostsStore.shared

        // 1. 未分组的方案（如 Default）
        let ungroupedProfiles = hostsStore.config.profiles.filter { $0.groupId == nil }
        for profile in ungroupedProfiles {
            let item = NSMenuItem(
                title: profile.title,
                action: #selector(toggleProfileClicked(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = profile.id
            item.state = profile.isEnabled ? .on : .off
            menu.addItem(item)
        }

        // 2. 分组（如 Demo Domain）
        for group in hostsStore.config.groups {
            let groupItem = NSMenuItem(title: group.title, action: nil, keyEquivalent: "")
            let folderImage = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
            groupItem.image = folderImage

            let subMenu = NSMenu()
            let groupProfiles = hostsStore.config.profiles.filter { $0.groupId == group.id }
            for profile in groupProfiles {
                let item = NSMenuItem(
                    title: profile.title,
                    action: #selector(toggleProfileClicked(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = profile.id
                item.state = profile.isEnabled ? .on : .off
                subMenu.addItem(item)
            }
            groupItem.submenu = subMenu
            menu.addItem(groupItem)
        }

        menu.addItem(NSMenuItem.separator())

        // 3. Hosts 操作快捷入口
        let editItem = NSMenuItem(title: loc(.menuEditHosts), action: #selector(openEditHostsAction), keyEquivalent: "e")
        editItem.target = self
        menu.addItem(editItem)

        let viewItem = NSMenuItem(title: loc(.menuViewHosts), action: #selector(openViewHostsAction), keyEquivalent: "v")
        viewItem.target = self
        menu.addItem(viewItem)

        menu.addItem(NSMenuItem.separator())

        // 4. 应用切换调色板
        let triggerName = ConfigStore.shared.config.triggerKeyName
        let paletteItem = NSMenuItem(title: "\(loc(.menuTogglePalette)) (\(triggerName))", action: #selector(togglePaletteAction), keyEquivalent: "")
        paletteItem.target = self
        menu.addItem(paletteItem)

        // 5. 触控板手势管理
        let gestureStore = GestureStore.shared
        let gestureStatusText = gestureStore.isGlobalEnabled ? (LocalizationManager.shared.currentLanguage == .english ? "Enabled" : "已启用") : (LocalizationManager.shared.currentLanguage == .english ? "Paused" : "已暂停")
        let gestureItem = NSMenuItem(title: "\(loc(.menuTouchGestures)) (\(gestureStatusText))", action: nil, keyEquivalent: "")
        let gestureSub = NSMenu()
        let toggleGlobalItem = NSMenuItem(
            title: gestureStore.isGlobalEnabled ? loc(.menuGesturesActive) : loc(.menuGesturesPaused),
            action: #selector(toggleGesturesGlobalAction),
            keyEquivalent: ""
        )
        toggleGlobalItem.target = self
        gestureSub.addItem(toggleGlobalItem)
        gestureSub.addItem(NSMenuItem.separator())
        let openGestureSettingItem = NSMenuItem(title: loc(.menuGestureSettings), action: #selector(openTrackpadAction), keyEquivalent: "t")
        openGestureSettingItem.target = self
        gestureSub.addItem(openGestureSettingItem)
        gestureItem.submenu = gestureSub
        menu.addItem(gestureItem)

        menu.addItem(NSMenuItem.separator())

        // 6. 设置主窗口
        let settingsItem = NSMenuItem(title: loc(.menuPreferences), action: #selector(openSettingsAction), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 7. 退出
        let quitItem = NSMenuItem(title: loc(.menuQuit), action: #selector(quitAction), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func toggleProfileClicked(_ sender: NSMenuItem) {
        guard let id = sender.representedObject as? UUID else { return }
        HostsStore.shared.toggleProfile(id: id)
        rebuildMenu()
    }

    @objc private func openEditHostsAction() {
        MainWindowController.shared.showWindow(tab: .editHosts)
    }

    @objc private func openViewHostsAction() {
        MainWindowController.shared.showWindow(tab: .viewHosts)
    }

    @objc private func togglePaletteAction() {
        PaletteWindowController.shared.toggle()
    }

    @objc private func openSettingsAction() {
        MainWindowController.shared.showWindow(tab: .general)
    }

    @objc private func toggleGesturesGlobalAction() {
        GestureStore.shared.isGlobalEnabled.toggle()
        rebuildMenu()
    }

    @objc private func openTrackpadAction() {
        MainWindowController.shared.showWindow(tab: .trackpad)
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }

    /// 创建契合 Deck 品牌标志的原生矢量菜单栏模版图标 | )
    public static func createDeckMenuBarIcon() -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size, flipped: false) { rect in
            // 1. 左侧垂直圆角矩形条 |
            let barRect = NSRect(x: 2.8, y: 2.5, width: 2.4, height: 13.0)
            let barPath = NSBezierPath(roundedRect: barRect, xRadius: 1.2, yRadius: 1.2)
            NSColor.black.setFill()
            barPath.fill()

            // 2. 右侧半圆弧形 )
            let arcPath = NSBezierPath()
            let center = NSPoint(x: 8.8, y: 9.0)
            let outerR: CGFloat = 6.5
            let innerR: CGFloat = 4.1

            arcPath.appendArc(withCenter: center, radius: outerR, startAngle: 90, endAngle: -90, clockwise: true)
            arcPath.line(to: NSPoint(x: center.x, y: center.y - innerR))
            arcPath.appendArc(withCenter: center, radius: innerR, startAngle: -90, endAngle: 90, clockwise: false)
            arcPath.close()
            arcPath.fill()

            return true
        }
        image.isTemplate = true
        return image
    }
}
