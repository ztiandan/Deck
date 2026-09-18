import Foundation
import AppKit

public class AppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // 设置为后台代理应用（状态栏运行，不占用 Dock）
        NSApp.setActivationPolicy(.accessory)

        // 初始化状态栏托盘菜单与标准主菜单
        MenuBarManager.shared.setupMenuBar()
        setupMainMenu()

        // 初始化 Hosts 管理
        _ = HostsStore.shared

        // 设置全局应用调色板热键触发
        HotKeyManager.shared.onTrigger = {
            PaletteWindowController.shared.toggle()
        }

        // 检查辅助功能权限并开始监听全局 F18 键
        let trusted = HotKeyManager.shared.checkAccessibility(prompt: false)
        if trusted {
            HotKeyManager.shared.startListening()
        } else {
            // 轮询权限状态，一旦授权则自动启动全局监听
            Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
                if HotKeyManager.shared.checkAccessibility(prompt: false) {
                    HotKeyManager.shared.startListening()
                    MenuBarManager.shared.rebuildMenu()
                    timer.invalidate()
                }
            }
        }

        // 初始化触控板手势增强引擎
        TouchpadManager.shared.start()

        // 监听语言切换以更新主菜单、托盘菜单与默认手势备注
        LocalizationManager.shared.onLanguageChanged = { [weak self] in
            self?.setupMainMenu()
            MenuBarManager.shared.rebuildMenu()
            GestureStore.shared.updateNotesLanguage(to: LocalizationManager.shared.currentLanguage)
        }

        // 启动时展示主窗口
        DispatchQueue.main.async {
            MainWindowController.shared.showWindow(tab: .appSwitcher)
        }
    }

    public func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.stopListening()
        TouchpadManager.shared.stop()
    }

    public func setupMainMenu() {
        let mainMenu = NSMenu()

        // 应用程序主菜单
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: loc(.menuAbout), action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: loc(.menuPreferences), action: #selector(openPreferences), keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: loc(.menuQuit), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 文件菜单
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: loc(.menuFile))
        let closeItem = NSMenuItem(title: loc(.menuCloseWindow), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenu.addItem(closeItem)
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // 编辑菜单
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: loc(.menuEdit))
        editMenu.addItem(withTitle: loc(.menuUndo), action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: loc(.menuRedo), action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: loc(.menuCut), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: loc(.menuCopy), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: loc(.menuPaste), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: loc(.menuSelectAll), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 窗口菜单
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: loc(.menuWindow))
        windowMenu.addItem(withTitle: loc(.menuCloseWindow), action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowMenu.addItem(withTitle: loc(.menuMinimize), action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    @objc private func openPreferences() {
        MainWindowController.shared.showWindow(tab: .general)
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MainWindowController.shared.showWindow(tab: .appSwitcher)
        return true
    }
}
