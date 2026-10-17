import Foundation

protocol TouchpadInput: AnyObject {
    func start(onFrame: @escaping ([MTTouch], Double) -> Void) -> Bool
    func stop()
}

/// Owns one native registration. A restart reacquires the default device.
final class MultitouchInput: TouchpadInput {
    private let bridge: MultitouchBridge
    private var device: MTDeviceRef?
    private static let callbackLock = NSLock()
    private static var handlers: [MTDeviceRef: ([MTTouch], Double) -> Void] = [:]

    init(bridge: MultitouchBridge = .shared) {
        self.bridge = bridge
    }

    private static let callback: MTContactCallback = { device, rawTouches, count, timestamp, _ in
        guard let device, count >= 0, count == 0 || rawTouches != nil else { return 0 }
        callbackLock.lock()
        let handler = handlers[device]
        callbackLock.unlock()
        guard let handler else { return 0 }
        // The framework owns the buffer; copy before leaving its callback thread.
        // A nil buffer with count == 0 is a valid all-fingers-lifted frame.
        let touches = rawTouches.map {
            Array(UnsafeBufferPointer(start: $0.assumingMemoryBound(to: MTTouch.self), count: Int(count)))
        } ?? []
        handler(touches, timestamp)
        return 0
    }

    func start(onFrame: @escaping ([MTTouch], Double) -> Void) -> Bool {
        stop()
        guard bridge.isAvailable, let created = bridge.MTDeviceCreateDefault?() else { return false }
        device = created
        Self.callbackLock.lock()
        Self.handlers[created] = onFrame
        Self.callbackLock.unlock()
        bridge.MTRegisterContactFrameCallback?(created, Self.callback)
        bridge.MTDeviceStart?(created, 0)
        if let isRunning = bridge.MTDeviceIsRunning, !isRunning(created) {
            stop()
            return false
        }
        return true
    }

    func stop() {
        guard let device else { return }
        self.device = nil
        Self.callbackLock.lock()
        Self.handlers.removeValue(forKey: device)
        Self.callbackLock.unlock()
        bridge.MTDeviceStop?(device)
        bridge.MTUnregisterContactFrameCallback?(device, Self.callback)
        bridge.MTDeviceRelease?(device)
    }

    deinit { stop() }
}
