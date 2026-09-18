import Foundation
import CoreGraphics

public enum GestureType: String, Codable, CaseIterable, Identifiable {
    case tipTapRight2F = "TipTap Right (2 Fingers Fix)"
    case tipTapLeft2F = "TipTap Left (2 Fingers Fix)"
    case tipTapLeft3F = "TipTap Left (3 Fingers Fix)"
    case tipTapRight3F = "TipTap Right (3 Fingers Fix)"
    case fourFingerTap = "4 Finger Tap"
    case threeFingerTap = "3 Finger Tap"

    public var id: String { self.rawValue }

    public var displayName: String {
        switch self {
        case .tipTapRight2F:
            return loc(.gestureTipTapRight2F)
        case .tipTapLeft2F:
            return loc(.gestureTipTapLeft2F)
        case .tipTapLeft3F:
            return loc(.gestureTipTapLeft3F)
        case .tipTapRight3F:
            return loc(.gestureTipTapRight3F)
        case .fourFingerTap:
            return loc(.gestureFourFingerTap)
        case .threeFingerTap:
            return loc(.gestureThreeFingerTap)
        }
    }

    public var description: String {
        switch self {
        case .tipTapRight2F:
            return loc(.gestureTipTapRight2FDesc)
        case .tipTapLeft2F:
            return loc(.gestureTipTapLeft2FDesc)
        case .tipTapLeft3F:
            return loc(.gestureTipTapLeft3FDesc)
        case .tipTapRight3F:
            return loc(.gestureTipTapRight3FDesc)
        case .fourFingerTap:
            return loc(.gestureFourFingerTapDesc)
        case .threeFingerTap:
            return loc(.gestureThreeFingerTapDesc)
        }
    }
}

public enum GestureActionType: String, Codable, CaseIterable {
    case shortcut = "shortcut"
    case cmdClick = "cmdClick"
    case middleClick = "middleClick"

    public var title: String {
        switch self {
        case .shortcut: return loc(.gestureActionShortcut)
        case .cmdClick: return loc(.gestureActionCmdClick)
        case .middleClick: return loc(.gestureActionMiddleClick)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        switch raw {
        case "shortcut", "键盘快捷键":
            self = .shortcut
        case "cmdClick", "CMD(⌘) + 鼠标点击", "CMD(⌘) + 点击":
            self = .cmdClick
        case "middleClick", "鼠标中键点击", "鼠标中键":
            self = .middleClick
        default:
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported gesture action: \(raw)")
        }
    }
}

public struct TouchpadGesture: Identifiable, Codable, Equatable {
    public var id: UUID
    public var gestureType: GestureType
    public var actionType: GestureActionType
    public var shortcutDisplay: String
    public var keyCode: UInt16
    public var modifiers: [String] // "cmd", "shift", "ctrl", "opt"
    public var isEnabled: Bool
    public var notes: String

    public init(
        id: UUID = UUID(),
        gestureType: GestureType,
        actionType: GestureActionType = .shortcut,
        shortcutDisplay: String,
        keyCode: UInt16 = 0,
        modifiers: [String] = [],
        isEnabled: Bool = true,
        notes: String = ""
    ) {
        self.id = id
        self.gestureType = gestureType
        self.actionType = actionType
        self.shortcutDisplay = shortcutDisplay
        self.keyCode = keyCode
        self.modifiers = modifiers
        self.isEnabled = isEnabled
        self.notes = notes
    }
}
