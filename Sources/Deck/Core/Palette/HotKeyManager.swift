import Foundation
import AppKit
import CoreGraphics

public class HotKeyManager: ObservableObject {
    public static let shared = HotKeyManager()
    @Published public private(set) var isAccessibilityGranted = false
    @Published public private(set) var isListening = false
    public var onTrigger: (() -> Void)?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    private var pollingTimer: Timer?

    private init() {}

    @discardableResult
    public func checkAccessibility(prompt: Bool = false) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        isAccessibilityGranted = trusted
        if !trusted { stopListening() }
        return trusted
    }

    /// A single timer handles both permission grants/revocations and failed tap creation.
    public func startPollingAccessibility() {
        guard pollingTimer == nil else { return }
        refreshListening()
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshListening()
        }
    }

    private func refreshListening() {
        if checkAccessibility() && !isListening { startListening() }
    }

    public func stopPollingAccessibility() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    public func openAccessibilityPreferences() {
        checkAccessibility(prompt: true)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
        startPollingAccessibility()
    }

    static func isTrigger(_ event: CGEvent, keyCode: Int) -> Bool {
        event.getIntegerValueField(.keyboardEventKeycode) == keyCode &&
        event.flags.intersection([.maskCommand, .maskControl, .maskAlternate, .maskShift]).isEmpty
    }

    public func startListening() {
        guard !isListening, checkAccessibility() else { return }
        let observer = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: { _, type, event, refcon in
                guard let refcon else { return Unmanaged.passUnretained(event) }
                let manager = Unmanaged<HotKeyManager>.fromOpaque(refcon).takeUnretainedValue()
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = manager.eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
                    return Unmanaged.passUnretained(event)
                }
                if type == .keyDown && HotKeyManager.isTrigger(event, keyCode: ConfigStore.shared.config.triggerKeyCode) {
                    if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                        DispatchQueue.main.async { manager.onTrigger?() }
                    }
                    return nil
                }
                return Unmanaged.passUnretained(event)
            }, userInfo: observer
        ) else { return }
        eventTap = tap
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        isListening = true
    }

    public func stopListening() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            CFMachPortInvalidate(tap)
        }
        if let source = runLoopSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        runLoopSource = nil
        eventTap = nil
        isListening = false
    }

    public func restartListening() {
        stopListening()
        startListening()
    }
}
