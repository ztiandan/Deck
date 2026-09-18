import Foundation
import AppKit
import CoreGraphics

public class HotKeyManager: ObservableObject {
    public static let shared = HotKeyManager()

    @Published public var isAccessibilityGranted: Bool = false
    @Published public var isListening: Bool = false

    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    public var onTrigger: (() -> Void)?

    private init() {
        checkAccessibility(prompt: false)
    }

    /// 检查辅助功能权限
    @discardableResult
    public func checkAccessibility(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        DispatchQueue.main.async {
            self.isAccessibilityGranted = trusted
        }
        return trusted
    }

    /// 打开系统设置辅助功能设置页
    public func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// 开始监听全局热键
    public func startListening() {
        if isListening { return }

        guard checkAccessibility(prompt: true) else {
            print("Accessibility permission is required for global hotkey")
            return
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue)

        let observer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else { return Unmanaged.passRetained(event) }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(refcon).takeUnretainedValue()

                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let eventTap = manager.eventTap {
                        CGEvent.tapEnable(tap: eventTap, enable: true)
                    }
                    return Unmanaged.passRetained(event)
                }

                if type == .keyDown {
                    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
                    let targetKeyCode = ConfigStore.shared.config.triggerKeyCode

                    if keyCode == targetKeyCode {
                        DispatchQueue.main.async {
                            manager.onTrigger?()
                        }
                        // 吞掉此按键，防止蜂鸣或穿透
                        return nil
                    }
                }

                return Unmanaged.passRetained(event)
            },
            userInfo: observer
        ) else {
            print("Failed to create event tap")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.isListening = true
        print("Successfully started listening for trigger key (KeyCode: \(ConfigStore.shared.config.triggerKeyCode))")
    }

    /// 停止监听
    public func stopListening() {
        guard isListening else { return }
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
                self.runLoopSource = nil
            }
            self.eventTap = nil
        }
        self.isListening = false
    }

    /// 重启监听（例如修改了热键之后）
    public func restartListening() {
        stopListening()
        startListening()
    }
}
