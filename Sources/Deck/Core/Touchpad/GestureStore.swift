import Foundation
import Combine

public class GestureStore: ObservableObject {
    public static let shared = GestureStore()

    @Published public var gestures: [TouchpadGesture] = [] {
        didSet {
            if !isLoading { save() }
        }
    }
    @Published public var isGlobalEnabled: Bool {
        didSet { preferences.set(isGlobalEnabled, forKey: "deck_gesture_enabled") }
    }
    @Published public var isHapticFeedbackEnabled: Bool {
        didSet {
            preferences.set(isHapticFeedbackEnabled, forKey: "deck_gesture_haptic_feedback")
        }
    }

    private let fileURL: URL
    private let preferences: UserDefaults
    private var isLoading = false

    init(fileURL: URL? = nil, preferences: UserDefaults = .standard) {
        self.preferences = preferences
        self.isGlobalEnabled = preferences.object(forKey: "deck_gesture_enabled") as? Bool ?? true
        self.isHapticFeedbackEnabled = preferences.object(forKey: "deck_gesture_haptic_feedback") as? Bool ?? true
        if let fileURL {
            self.fileURL = fileURL
            load()
            return
        }

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
        isLoading = true
        defer { isLoading = false }
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                var decoded = try JSONDecoder().decode([TouchpadGesture].self, from: data)
                sanitizeNotes(&decoded)
                gestures = decoded
            } catch {
                ConfigurationIssue.shared.report(error, url: fileURL)
            }
            return
        }
        gestures = defaultGestures()
        save()
    }

    public func sanitizeNotes(_ list: inout [TouchpadGesture]) {
        let isEnglish = LocalizationManager.shared.currentLanguage == .english
        for i in 0..<list.count {
            // 修复历史遗留的 tipTapLeft3F 按键偏差（右箭头 -> 左箭头）
            if list[i].gestureType == .tipTapLeft3F && list[i].shortcutDisplay == "^ ⇧ →" && list[i].keyCode == 124 {
                list[i].shortcutDisplay = "^ ←"
                list[i].keyCode = 123
                list[i].modifiers = ["ctrl"]
            }

            switch list[i].notes {
            case "关闭标签页或窗口":
                if isEnglish { list[i].notes = "Close tab or window" }
            case "Close tab or window":
                if !isEnglish { list[i].notes = "关闭标签页或窗口" }
            case "刷新当前页面":
                if isEnglish { list[i].notes = "Reload current page" }
            case "Reload current page":
                if !isEnglish { list[i].notes = "刷新当前页面" }
            case "前一切换标签/桌面", "前一切换标签\\/桌面":
                if isEnglish { list[i].notes = "Previous tab or desktop" }
            case "Previous tab or desktop", "Previous tab or space":
                if !isEnglish { list[i].notes = "前一切换标签/桌面" }
            case "后一切换标签/桌面", "后一切换标签\\/桌面":
                if isEnglish { list[i].notes = "Next tab or desktop" }
            case "Next tab or desktop", "Next tab or space":
                if !isEnglish { list[i].notes = "后一切换标签/桌面" }
            case "后台新标签打开网页":
                if isEnglish { list[i].notes = "Open link in background tab" }
            case "Open link in background tab", "Open in background tab":
                if !isEnglish { list[i].notes = "后台新标签打开网页" }
            default:
                break
            }
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
            try ConfigurationFile.write(gestures, to: fileURL)
        } catch {
            ConfigurationIssue.shared.report(error, url: fileURL)
        }
    }

    public func addGesture(_ gesture: TouchpadGesture) {
        var updated = gestures
        if gesture.isEnabled {
            for i in updated.indices where updated[i].gestureType == gesture.gestureType {
                updated[i].isEnabled = false
            }
        }
        updated.append(gesture)
        gestures = updated
    }

    public func removeGesture(id: UUID) {
        gestures.removeAll { $0.id == id }
    }

    public func updateGesture(_ gesture: TouchpadGesture) {
        if let idx = gestures.firstIndex(where: { $0.id == gesture.id }) {
            var updated = gestures
            if gesture.isEnabled {
                for i in updated.indices where i != idx && updated[i].gestureType == gesture.gestureType {
                    updated[i].isEnabled = false
                }
            }
            updated[idx] = gesture
            gestures = updated
        }
    }

    public func toggleGesture(id: UUID) {
        if let idx = gestures.firstIndex(where: { $0.id == id }) {
            var gesture = gestures[idx]
            gesture.isEnabled.toggle()
            updateGesture(gesture)
        }
    }

    public func resetToDefault() {
        self.gestures = defaultGestures()
    }

    public func updateNotesLanguage(to lang: AppLanguage) {
        var current = gestures
        sanitizeNotes(&current)
        self.gestures = current
    }
}
