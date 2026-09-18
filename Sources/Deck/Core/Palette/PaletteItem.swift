import Foundation
import AppKit

public enum PaletteActionType: String, Codable, CaseIterable {
    case activateApp
    case activateLastApp
}

public struct PaletteItem: Identifiable, Codable, Equatable {
    public var id: UUID
    public var key: String
    public var displayName: String
    public var actionType: PaletteActionType
    public var bundleIdentifier: String?
    public var appPath: String?

    public init(
        id: UUID = UUID(),
        key: String,
        displayName: String,
        actionType: PaletteActionType = .activateApp,
        bundleIdentifier: String? = nil,
        appPath: String? = nil
    ) {
        self.id = id
        self.key = key
        self.displayName = displayName
        self.actionType = actionType
        self.bundleIdentifier = bundleIdentifier
        self.appPath = appPath
    }

    /// 获取代表此条目的图标
    public func icon() -> NSImage {
        if actionType == .activateLastApp {
            if let image = NSImage(systemSymbolName: "arrow.uturn.backward.circle.fill", accessibilityDescription: "Last Application") {
                return image
            }
            return NSWorkspace.shared.icon(for: .application)
        }

        // 尝试从应用路径获取
        if let appPath = appPath, FileManager.default.fileExists(atPath: appPath) {
            return NSWorkspace.shared.icon(forFile: appPath)
        }

        // 尝试从 Bundle Identifier 获取
        if let bundleId = bundleIdentifier,
           let appUrl = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: appUrl.path)
        }

        // 兜底返回系统通用应用程序图标
        return NSWorkspace.shared.icon(for: .application)
    }

    /// 友好显示的按键标签（如空格显示为 "Space"）
    public var displayKey: String {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        if key == " " || trimmed.lowercased() == "space" || trimmed == "␣" || trimmed == "空格" {
            return "Space"
        }
        return key
    }

    /// 判断按键事件是否与当前配置项匹配
    public func matches(event: NSEvent) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        let isSpaceConfigured = key == " " || trimmed.lowercased() == "space" || trimmed == "␣" || trimmed == "空格"

        // 1. 按下空格键 (kVK_Space == 49)
        if event.keyCode == 49 {
            return isSpaceConfigured
        }

        // 2. 匹配字符输入
        guard let chars = event.characters, !chars.isEmpty else { return false }
        if isSpaceConfigured && chars == " " {
            return true
        }

        let pressed = chars.lowercased()
        return key == chars || key.lowercased() == pressed
    }
}
