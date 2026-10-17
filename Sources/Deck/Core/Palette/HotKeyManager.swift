import Foundation
import AppKit
import CoreGraphics

/// Keeps event-tap health and ownership separate from the recovery policy.
protocol HotKeyEventTap: AnyObject {
    var isValid: Bool { get }
    var isEnabled: Bool { get }
    func setEnabled(_ enabled: Bool)
    func invalidate()
}

private final class SystemHotKeyEventTap: HotKeyEventTap {
    private let port: CFMachPort
    private let source: CFRunLoopSource
    private var isInvalidated = false

    init?(callback: CGEventTapCallBack, userInfo: UnsafeMutableRawPointer) {
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .defaultTap,
            eventsOfInterest: CGEventMask(1 << CGEventType.keyDown.rawValue),
            callback: callback, userInfo: userInfo
        ) else { return nil }
        guard let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0) else {
            CFMachPortInvalidate(port)
            return nil
        }
        self.port = port
        self.source = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
    }

    var isValid: Bool { !isInvalidated && CFMachPortIsValid(port) && CFRunLoopSourceIsValid(source) }
    var isEnabled: Bool { isValid && CGEvent.tapIsEnabled(tap: port) }

    func setEnabled(_ enabled: Bool) {
        if isValid { CGEvent.tapEnable(tap: port, enable: enabled) }
    }

    func invalidate() {
        guard !isInvalidated else { return }
        setEnabled(false)
        isInvalidated = true
        CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes)
        CFRunLoopSourceInvalidate(source)
        CFMachPortInvalidate(port)
    }

    deinit { invalidate() }
}

public class HotKeyManager: ObservableObject {
    public static let shared = HotKeyManager()
    @Published public private(set) var isAccessibilityGranted = false
    @Published public private(set) var isListening = false
    public var onTrigger: (() -> Void)?
    private var eventTap: HotKeyEventTap?
    private var pollingTimer: Timer?
    private var isSuspended = false
    private var listeningGeneration = 0
    private let accessibilityCheck: (Bool) -> Bool
    private let makeEventTap: (CGEventTapCallBack, UnsafeMutableRawPointer) -> HotKeyEventTap?

    private convenience init() {
        self.init(accessibilityCheck: { prompt in
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
            return AXIsProcessTrustedWithOptions(options)
        }, makeEventTap: { SystemHotKeyEventTap(callback: $0, userInfo: $1) })
    }

    init(accessibilityCheck: @escaping (Bool) -> Bool,
         makeEventTap: @escaping (CGEventTapCallBack, UnsafeMutableRawPointer) -> HotKeyEventTap?) {
        self.accessibilityCheck = accessibilityCheck
        self.makeEventTap = makeEventTap
    }

    deinit {
        pollingTimer?.invalidate()
        eventTap?.invalidate()
    }

    @discardableResult
    public func checkAccessibility(prompt: Bool = false) -> Bool {
        let trusted = accessibilityCheck(prompt)
        isAccessibilityGranted = trusted
        if !trusted { stopListening() }
        return trusted
    }

    /// One timer handles permission changes, failed creation, and silently disabled taps.
    public func startPollingAccessibility() {
        refreshListening()
        guard pollingTimer == nil else { return }
        let timer = Timer(timeInterval: 2, repeats: true) { [weak self] _ in
            self?.refreshListening()
        }
        pollingTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func refreshListening() {
        guard !isSuspended, checkAccessibility() else { return }
        if let tap = eventTap, tap.isValid {
            if !tap.isEnabled { tap.setEnabled(true) }
            if tap.isEnabled {
                isListening = true
                return
            }
        }
        // A retained Mach port is not proof that WindowServer still delivers events.
        stopListening()
        startListening()
    }

    public func stopPollingAccessibility() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    public func suspend() {
        isSuspended = true
        stopListening()
    }

    public func resume() {
        isSuspended = false
        // Always obtain a new tap after wake or user-session activation.
        stopListening()
        startPollingAccessibility()
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
        guard !isSuspended, !isListening, checkAccessibility() else { return }
        if eventTap != nil { stopListening() }
        let observer = Unmanaged.passUnretained(self).toOpaque()
        guard let tap = makeEventTap({ _, type, event, refcon in
            guard let refcon else { return Unmanaged.passUnretained(event) }
            let manager = Unmanaged<HotKeyManager>.fromOpaque(refcon).takeUnretainedValue()
            guard !manager.isSuspended else { return Unmanaged.passUnretained(event) }
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                manager.eventTap?.setEnabled(true)
                manager.isListening = manager.eventTap?.isEnabled == true
                return Unmanaged.passUnretained(event)
            }
            if type == .keyDown && HotKeyManager.isTrigger(event, keyCode: ConfigStore.shared.config.triggerKeyCode) {
                if event.getIntegerValueField(.keyboardEventAutorepeat) == 0 {
                    let generation = manager.listeningGeneration
                    DispatchQueue.main.async { [weak manager] in
                        guard let manager, manager.isListening, !manager.isSuspended,
                              manager.listeningGeneration == generation else { return }
                        manager.onTrigger?()
                    }
                }
                return nil
            }
            return Unmanaged.passUnretained(event)
        }, observer) else { return }
        eventTap = tap
        tap.setEnabled(true)
        isListening = tap.isEnabled
        if !isListening { stopListening() }
    }

    public func stopListening() {
        listeningGeneration &+= 1
        eventTap?.invalidate()
        eventTap = nil
        isListening = false
    }

    public func restartListening() {
        stopListening()
        startListening()
    }
}
