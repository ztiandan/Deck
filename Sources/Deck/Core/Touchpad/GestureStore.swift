import Foundation
import Combine

public class GestureStore: ObservableObject {
    public static let shared = GestureStore()

    @Published public var gestures: [TouchpadGesture] = [] {
        didSet {
            save()
        }
    }
    @Published public var isGlobalEnabled: Bool = true

    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Deck", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        let targetURL = appDir.appendingPathComponent("gestures.json")

        // 迁移旧版配置（如有）
        if !FileManager.default.fileExists(atPath: targetURL.path) {
            let oldHyperKit = appSupport.appendingPathComponent("HyperKit/gestures.json")
            if FileManager.default.fileExists(atPath: oldHyperKit.path) {
                try? FileManager.default.copyItem(at: oldHyperKit, to: targetURL)
            }
        }

        self.fileURL = targetURL
        load()
    }

    public func load() {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                var decoded = try JSONDecoder().decode([TouchpadGesture].self, from: data)
                if !decoded.isEmpty {
                    sanitizeNotes(&decoded)
                    self.gestures = decoded
                    return
                }
            } catch {
                print("Failed to load gestures: \(error), using default")
            }
        }

        // Default preset productivity gestures
        self.gestures = defaultGestures()
        save()
    }

    public func sanitizeNotes(_ list: inout [TouchpadGesture]) {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        var modified = false
        for i in 0..<list.count {
            // 修复历史遗留的 tipTapLeft3F 按键偏差（右箭头 -> 左箭头）
            if list[i].gestureType == .tipTapLeft3F && list[i].shortcutDisplay == "^ ⇧ →" && list[i].keyCode == 124 {
                list[i].shortcutDisplay = "^ ←"
                list[i].keyCode = 123
                list[i].modifiers = ["ctrl"]
                modified = true
            }

            switch list[i].notes {
            case "关闭标签页或窗口":
                if isEnglish { list[i].notes = "Close tab or window"; modified = true }
            case "Close tab or window":
                if !isEnglish { list[i].notes = "关闭标签页或窗口"; modified = true }
            case "刷新当前页面":
                if isEnglish { list[i].notes = "Reload current page"; modified = true }
            case "Reload current page":
                if !isEnglish { list[i].notes = "刷新当前页面"; modified = true }
            case "前一切换标签/桌面", "前一切换标签\\/桌面":
                if isEnglish { list[i].notes = "Previous tab or desktop"; modified = true }
            case "Previous tab or desktop", "Previous tab or space":
                if !isEnglish { list[i].notes = "前一切换标签/桌面"; modified = true }
            case "后一切换标签/桌面", "后一切换标签\\/桌面":
                if isEnglish { list[i].notes = "Next tab or desktop"; modified = true }
            case "Next tab or desktop", "Next tab or space":
                if !isEnglish { list[i].notes = "后一切换标签/桌面"; modified = true }
            case "后台新标签打开网页":
                if isEnglish { list[i].notes = "Open link in background tab"; modified = true }
            case "Open link in background tab", "Open in background tab":
                if !isEnglish { list[i].notes = "后台新标签打开网页"; modified = true }
            default:
                break
            }
        }
        if modified {
            save()
        }
    }

    public func defaultGestures() -> [TouchpadGesture] {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        return [
            TouchpadGesture(
                gestureType: .tipTapRight2F,
                actionType: .shortcut,
                shortcutDisplay: "⌘ W",
                keyCode: 13, // W
                modifiers: ["cmd"],
                notes: isEnglish ? "Close tab or window" : "关闭标签页或窗口"
            ),
            TouchpadGesture(
                gestureType: .tipTapLeft2F,
                actionType: .shortcut,
                shortcutDisplay: "⌘ R",
                keyCode: 15, // R
                modifiers: ["cmd"],
                notes: isEnglish ? "Reload current page" : "刷新当前页面"
            ),
            TouchpadGesture(
                gestureType: .tipTapLeft3F,
                actionType: .shortcut,
                shortcutDisplay: "^ ←",
                keyCode: 123, // Left Arrow
                modifiers: ["ctrl"],
                notes: isEnglish ? "Previous tab or desktop" : "前一切换标签/桌面"
            ),
            TouchpadGesture(
                gestureType: .tipTapRight3F,
                actionType: .shortcut,
                shortcutDisplay: "^ →",
                keyCode: 124, // Right Arrow
                modifiers: ["ctrl"],
                notes: isEnglish ? "Next tab or desktop" : "后一切换标签/桌面"
            ),
            TouchpadGesture(
                gestureType: .fourFingerTap,
                actionType: .cmdClick,
                shortcutDisplay: "CMD(⌘)+Click",
                notes: isEnglish ? "Open link in background tab" : "后台新标签打开网页"
            )
        ]
    }

    public func save() {
        do {
            let data = try JSONEncoder().encode(gestures)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save gestures: \(error)")
        }
    }

    public func addGesture(_ gesture: TouchpadGesture) {
        gestures.append(gesture)
        save()
    }

    public func removeGesture(id: UUID) {
        gestures.removeAll { $0.id == id }
        save()
    }

    public func updateGesture(_ gesture: TouchpadGesture) {
        if let idx = gestures.firstIndex(where: { $0.id == gesture.id }) {
            gestures[idx] = gesture
            save()
        }
    }

    public func toggleGesture(id: UUID) {
        if let idx = gestures.firstIndex(where: { $0.id == id }) {
            gestures[idx].isEnabled.toggle()
            save()
        }
    }

    public func resetToDefault() {
        self.gestures = defaultGestures()
        save()
    }

    public func updateNotesLanguage(to lang: AppLanguage) {
        var current = gestures
        sanitizeNotes(&current)
        self.gestures = current
    }
}
