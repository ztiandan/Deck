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

    static func normalizedKey(_ key: String) -> String? {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if key == " " || ["space", "␣", "空格"].contains(trimmed.lowercased()) { return " " }
        guard trimmed.count == 1, !trimmed.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else { return nil }
        return trimmed.lowercased()
    }

    static func keyValidationError(_ key: String, excluding id: UUID? = nil, items: [PaletteItem]) -> L10nKey? {
        guard let normalized = normalizedKey(key) else { return .paletteKeyInvalid }
        if items.contains(where: { $0.id != id && normalizedKey($0.key) == normalized }) {
            return .paletteKeyDuplicate
        }
        return nil
    }

    static func action(for event: NSEvent, items: [PaletteItem]) -> PaletteItem? {
        guard !event.isARepeat,
              event.modifierFlags.intersection([.command, .control, .option]).isEmpty else { return nil }
        if let matched = items.first(where: { $0.matches(event: event) }) { return matched }
        if event.keyCode == 49 { return items.first(where: { $0.actionType == .activateLastApp }) }
        return nil
    }

    /// Plain keys only: Command-C in the HUD must not accidentally activate Chrome.
    public func matches(event: NSEvent) -> Bool {
        guard event.modifierFlags.intersection([.command, .control, .option]).isEmpty,
              let configured = Self.normalizedKey(key) else { return false }
        if event.keyCode == 49 { return configured == " " }
        guard let chars = event.characters, !chars.isEmpty else { return false }
        return configured == chars.lowercased()
    }
}
