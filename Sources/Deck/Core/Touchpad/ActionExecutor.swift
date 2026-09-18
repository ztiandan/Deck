import Foundation
import AppKit
import CoreGraphics

public class ActionExecutor {
    public static let shared = ActionExecutor()

    private init() {}

    public func execute(gesture: TouchpadGesture) {
        guard gesture.isEnabled else { return }

        switch gesture.actionType {
        case .shortcut:
            simulateShortcut(keyCode: gesture.keyCode, modifiers: gesture.modifiers)
        case .cmdClick:
            simulateCmdClick()
        case .middleClick:
            simulateMiddleClick()
        }
    }

    /// 模拟键盘快捷键
    public func simulateShortcut(keyCode: UInt16, modifiers: [String]) {
        var flags: CGEventFlags = []
        for mod in modifiers {
            switch mod.lowercased() {
            case "cmd", "command":
                flags.insert(.maskCommand)
            case "shift":
                flags.insert(.maskShift)
            case "ctrl", "control":
                flags.insert(.maskControl)
            case "opt", "option", "alt":
                flags.insert(.maskAlternate)
            default:
                break
            }
        }

        let src = CGEventSource(stateID: .combinedSessionState)

        guard let keyDown = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(keyCode), keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: src, virtualKey: CGKeyCode(keyCode), keyDown: false) else {
            return
        }

        keyDown.flags = flags
        keyUp.flags = flags

        keyDown.post(tap: .cghidEventTap)
        usleep(20000) // 20ms
        keyUp.post(tap: .cghidEventTap)
    }

    /// 模拟 CMD + 鼠标左键点击（常用于后台新标签打开）
    public func simulateCmdClick() {
        let mouseLoc = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return }
        // 转换 macOS 屏幕坐标（Y轴翻转）
        let point = CGPoint(x: mouseLoc.x, y: screen.frame.height - mouseLoc.y)

        let src = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
              let up = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
            return
        }

        down.flags = .maskCommand
        up.flags = .maskCommand

        down.post(tap: .cghidEventTap)
        usleep(20000)
        up.post(tap: .cghidEventTap)
    }

    /// 模拟鼠标中键点击
    public func simulateMiddleClick() {
        let mouseLoc = NSEvent.mouseLocation
        guard let screen = NSScreen.main else { return }
        let point = CGPoint(x: mouseLoc.x, y: screen.frame.height - mouseLoc.y)

        let src = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(mouseEventSource: src, mouseType: .otherMouseDown, mouseCursorPosition: point, mouseButton: .center),
              let up = CGEvent(mouseEventSource: src, mouseType: .otherMouseUp, mouseCursorPosition: point, mouseButton: .center) else {
            return
        }

        down.setIntegerValueField(.mouseEventButtonNumber, value: 2)
        up.setIntegerValueField(.mouseEventButtonNumber, value: 2)

        down.post(tap: .cghidEventTap)
        usleep(20000)
        up.post(tap: .cghidEventTap)
    }
}
