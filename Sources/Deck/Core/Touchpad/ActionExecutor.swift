import Foundation
import AppKit
import CoreGraphics

public class ActionExecutor {
    public static let shared = ActionExecutor()

    private let postEvent: (CGEvent) -> Void

    init(postEvent: @escaping (CGEvent) -> Void = { $0.post(tap: .cghidEventTap) }) {
        self.postEvent = postEvent
    }

    public func execute(gesture: TouchpadGesture) {
        guard gesture.isEnabled else { return }

        switch gesture.actionType {
        case .shortcut:
            guard let (code, mods) = resolveKeyAndModifiers(gesture: gesture) else { return }
            simulateShortcut(keyCode: code, modifiers: mods)
        case .cmdClick:
            simulateCmdClick()
        case .middleClick:
            simulateMiddleClick()
        }
    }

    func resolveKeyAndModifiers(gesture: TouchpadGesture) -> (UInt16, [String])? {
        // The editable label is authoritative; stale saved key codes must not execute
        // a different shortcut (or accidentally type A when parsing fails).
        ShortcutDefinition.parse(gesture.shortcutDisplay).map { ($0.keyCode, $0.modifiers) }
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

        postEvent(keyDown)
        usleep(20000) // 20ms
        postEvent(keyUp)
    }

    /// 模拟 CMD + 鼠标左键点击（常用于后台新标签打开）
    public func simulateCmdClick() {
        let mouseLoc = NSEvent.mouseLocation
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        let fallbackPoint = CGPoint(x: mouseLoc.x, y: primaryHeight - mouseLoc.y)
        let point = CGEvent(source: nil)?.location ?? fallbackPoint

        let src = CGEventSource(stateID: .combinedSessionState)

        // 模拟 Command 键按下以确保浏览器（Chrome/Safari等）百分之百识别修饰键
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 55, keyDown: true)
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 55, keyDown: false)
        cmdDown?.flags = .maskCommand
        cmdUp?.flags = []

        guard let down = CGEvent(mouseEventSource: src, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
              let up = CGEvent(mouseEventSource: src, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
            return
        }

        down.flags = .maskCommand
        up.flags = .maskCommand

        down.setIntegerValueField(.mouseEventButtonNumber, value: 0)
        up.setIntegerValueField(.mouseEventButtonNumber, value: 0)
        down.setIntegerValueField(.mouseEventClickState, value: 1)
        up.setIntegerValueField(.mouseEventClickState, value: 1)

        if let event = cmdDown { postEvent(event) }
        usleep(5000)
        postEvent(down)
        usleep(25000)
        postEvent(up)
        usleep(5000)
        if let event = cmdUp { postEvent(event) }
    }

    /// 模拟鼠标中键点击
    public func simulateMiddleClick() {
        let mouseLoc = NSEvent.mouseLocation
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        let fallbackPoint = CGPoint(x: mouseLoc.x, y: primaryHeight - mouseLoc.y)
        let point = CGEvent(source: nil)?.location ?? fallbackPoint

        let src = CGEventSource(stateID: .combinedSessionState)
        guard let down = CGEvent(mouseEventSource: src, mouseType: .otherMouseDown, mouseCursorPosition: point, mouseButton: .center),
              let up = CGEvent(mouseEventSource: src, mouseType: .otherMouseUp, mouseCursorPosition: point, mouseButton: .center) else {
            return
        }

        down.flags = []
        up.flags = []
        down.setIntegerValueField(.mouseEventButtonNumber, value: 2)
        up.setIntegerValueField(.mouseEventButtonNumber, value: 2)
        down.setIntegerValueField(.mouseEventClickState, value: 1)
        up.setIntegerValueField(.mouseEventClickState, value: 1)

        postEvent(down)
        usleep(25000)
        postEvent(up)
    }
}
