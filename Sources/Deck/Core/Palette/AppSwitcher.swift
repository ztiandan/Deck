import Foundation
import AppKit

public class AppSwitcher {
    public static let shared = AppSwitcher()

    private var currentActiveApp: NSRunningApplication?
    private var previousApp: NSRunningApplication?

    private init() {
        startTrackingActiveApplication()
    }

    private func startTrackingActiveApplication() {
        let current = NSWorkspace.shared.frontmostApplication
        if current?.bundleIdentifier != Bundle.main.bundleIdentifier {
            currentActiveApp = current
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            guard let activatedApp = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }

            // 忽略我们自己的应用
            if activatedApp.bundleIdentifier == Bundle.main.bundleIdentifier {
                return
            }

            // 更新上一个应用
            if let current = self.currentActiveApp, current.processIdentifier != activatedApp.processIdentifier {
                self.previousApp = current
            }
            self.currentActiveApp = activatedApp
        }
    }

    /// 执行 PaletteItem 对应的操作
    public func execute(item: PaletteItem) {
        switch item.actionType {
        case .activateLastApp:
            activateLastApplication()
        case .activateApp:
            activateApplication(bundleIdentifier: item.bundleIdentifier, appPath: item.appPath, displayName: item.displayName)
        }
    }

    /// 切换到上一个活跃应用
    public func activateLastApplication() {
        if let prev = previousApp, !prev.isTerminated {
            prev.unhide()
            prev.activate(options: [.activateIgnoringOtherApps])
            return
        }

        // 如果没有记录的 previousApp，则寻找最近的一个非当前非后台的运行应用
        let apps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular &&
            $0.bundleIdentifier != Bundle.main.bundleIdentifier &&
            $0.processIdentifier != currentActiveApp?.processIdentifier
        }
        if let fallback = apps.first {
            fallback.unhide()
            fallback.activate(options: [.activateIgnoringOtherApps])
        }
    }

    /// 激活指定的应用
    public func activateApplication(bundleIdentifier: String?, appPath: String?, displayName: String? = nil) {
        // 1. 检查是否已经在运行
        let runningApps = NSWorkspace.shared.runningApplications

        if let bundleId = bundleIdentifier,
           let running = runningApps.first(where: { $0.bundleIdentifier == bundleId }) {
            running.unhide()
            running.activate(options: [.activateIgnoringOtherApps])
            return
        }

        if let path = appPath,
           let running = runningApps.first(where: { $0.bundleURL?.path == path }) {
            running.unhide()
            running.activate(options: [.activateIgnoringOtherApps])
            return
        }

        // 尝试通过名字在 runningApplications 中模糊匹配
        if let name = displayName {
            let cleanName = name.replacingOccurrences(of: "Activate ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            if let running = runningApps.first(where: {
                $0.localizedName?.localizedCaseInsensitiveContains(cleanName) == true
            }) {
                running.unhide()
                running.activate(options: [.activateIgnoringOtherApps])
                return
            }
        }

        // 2. 如果未运行，启动它
        var targetURL: URL?

        if let path = appPath, FileManager.default.fileExists(atPath: path) {
            targetURL = URL(fileURLWithPath: path)
        } else if let bundleId = bundleIdentifier,
                  let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            targetURL = url
        } else if let name = displayName {
            let cleanName = name.replacingOccurrences(of: "Activate ", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            // 尝试在 /Applications 或 /System/Applications 中寻找
            let candidatePaths = [
                "/Applications/\(cleanName).app",
                "/System/Applications/\(cleanName).app",
                "/Applications/Utilities/\(cleanName).app",
                "/System/Applications/Utilities/\(cleanName).app"
            ]
            for path in candidatePaths {
                if FileManager.default.fileExists(atPath: path) {
                    targetURL = URL(fileURLWithPath: path)
                    break
                }
            }
        }

        guard let appURL = targetURL else {
            print("Cannot find target app for item: \(displayName ?? "")")
            return
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { app, error in
            if let error = error {
                print("Failed to open application: \(error)")
            } else {
                app?.activate(options: [.activateIgnoringOtherApps])
            }
        }
    }
}
