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
}
