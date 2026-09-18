import Foundation
import Combine
import AppKit

public enum AppThemeMode: String, CaseIterable, Identifiable, Codable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    public var id: String { self.rawValue }

    public var title: String {
        switch self {
        case .light: return loc(.prefThemeLight)
        case .dark: return loc(.prefThemeDark)
        case .system: return loc(.prefThemeSystem)
        }
    }
}

public struct AppConfig: Codable {
    public var triggerKeyCode: Int = 79 // 0x4F: kVK_F18
    public var triggerKeyName: String = "F18"
    public var showAtCursor: Bool = false
    public var themeMode: AppThemeMode = .light
    public var items: [PaletteItem] = []

    public init() {}

    enum CodingKeys: String, CodingKey {
        case triggerKeyCode, triggerKeyName, showAtCursor, themeMode, items
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        triggerKeyCode = try container.decodeIfPresent(Int.self, forKey: .triggerKeyCode) ?? 79
        triggerKeyName = try container.decodeIfPresent(String.self, forKey: .triggerKeyName) ?? "F18"
        showAtCursor = try container.decodeIfPresent(Bool.self, forKey: .showAtCursor) ?? false
        themeMode = try container.decodeIfPresent(AppThemeMode.self, forKey: .themeMode) ?? .light
        items = try container.decodeIfPresent([PaletteItem].self, forKey: .items) ?? []
    }

    public static var `default`: AppConfig {
        var config = AppConfig()
        config.items = [
            PaletteItem(key: "|", displayName: "Activate Last Application", actionType: .activateLastApp),
            PaletteItem(key: "1", displayName: "Activate 1Password", actionType: .activateApp, bundleIdentifier: "com.1password.1password"),
            PaletteItem(key: "a", displayName: "Activate App Store", actionType: .activateApp, bundleIdentifier: "com.apple.AppStore"),
            PaletteItem(key: "c", displayName: "Activate Chrome", actionType: .activateApp, bundleIdentifier: "com.google.Chrome"),
            PaletteItem(key: "f", displayName: "Activate Finder", actionType: .activateApp, bundleIdentifier: "com.apple.finder"),
            PaletteItem(key: "i", displayName: "Activate iTerm", actionType: .activateApp, bundleIdentifier: "com.googlecode.iterm2"),
            PaletteItem(key: "k", displayName: "Activate Keynote", actionType: .activateApp, bundleIdentifier: "com.apple.iWork.Keynote"),
            PaletteItem(key: "n", displayName: "Activate NeteaseMusic", actionType: .activateApp, bundleIdentifier: "com.netease.163music"),
            PaletteItem(key: "o", displayName: "Activate Outlook", actionType: .activateApp, bundleIdentifier: "com.microsoft.Outlook"),
            PaletteItem(key: "p", displayName: "PyCharm", actionType: .activateApp, bundleIdentifier: "com.jetbrains.pycharm"),
            PaletteItem(key: "q", displayName: "Activate QQ", actionType: .activateApp, bundleIdentifier: "com.tencent.qq"),
            PaletteItem(key: "r", displayName: "Windows App", actionType: .activateApp, bundleIdentifier: "com.microsoft.rdc.macos"),
            PaletteItem(key: "s", displayName: "Activate Safari", actionType: .activateApp, bundleIdentifier: "com.apple.Safari"),
            PaletteItem(key: "v", displayName: "Activate Visual Studio Code", actionType: .activateApp, bundleIdentifier: "com.microsoft.VSCode"),
            PaletteItem(key: "w", displayName: "WebStorm", actionType: .activateApp, bundleIdentifier: "com.jetbrains.WebStorm"),
            PaletteItem(key: "x", displayName: "Activate Xcode", actionType: .activateApp, bundleIdentifier: "com.apple.dt.Xcode")
        ]
        return config
    }
}

public class ConfigStore: ObservableObject {
    public static let shared = ConfigStore()

    @Published public var config: AppConfig = .default

    private let fileURL: URL

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
            load()
            return
        }
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Deck", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        let targetURL = appDir.appendingPathComponent("config.json")

        // 迁移旧版配置（如有）
        if !FileManager.default.fileExists(atPath: targetURL.path) {
            let oldHyperKit = appSupport.appendingPathComponent("HyperKit/config.json")
            let oldQuickPalette = appSupport.appendingPathComponent("QuickPalette/config.json")
            if FileManager.default.fileExists(atPath: oldHyperKit.path) {
                try? FileManager.default.copyItem(at: oldHyperKit, to: targetURL)
            } else if FileManager.default.fileExists(atPath: oldQuickPalette.path) {
                try? FileManager.default.copyItem(at: oldQuickPalette, to: targetURL)
            }
        }

        self.fileURL = targetURL
        load()
    }

    public func load() {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                self.config = try JSONDecoder().decode(AppConfig.self, from: data)
                return
            } catch {
                ConfigurationIssue.shared.report(error, url: fileURL)
                return
            }
        }
        // 若没有或加载失败，使用默认并保存
        self.config = .default
        save()
    }

    public func save() {
        do {
            try ConfigurationFile.write(config, to: fileURL)
        } catch {
            ConfigurationIssue.shared.report(error, url: fileURL)
        }
    }

    public func addItem(_ item: PaletteItem) {
        config.items.append(item)
        save()
    }

    public func removeItem(id: UUID) {
        config.items.removeAll { $0.id == id }
        save()
    }

    public func updateItem(_ item: PaletteItem) {
        if let idx = config.items.firstIndex(where: { $0.id == item.id }) {
            config.items[idx] = item
            save()
        }
    }

    public func resetToDefault() {
        self.config = .default
        save()
    }
}
