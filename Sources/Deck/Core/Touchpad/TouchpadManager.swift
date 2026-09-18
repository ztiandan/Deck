import Foundation
import AppKit
import Combine

public class TouchpadManager: ObservableObject {
    public static let shared = TouchpadManager()

    @Published public var isRunning = false
    @Published public var lastTriggeredGesture: GestureType?

    private var device: MTDeviceRef?
    private var recognizer = GestureRecognizer()
    private var enabledSubscription: AnyCancellable?
    private var feedbackReset: DispatchWorkItem?

    private static let callback: MTContactCallback = { device, rawTouches, count, timestamp, _ in
        // The framework owns this buffer only for the duration of the callback.
        // A nil buffer with count == 0 is the final (all fingers lifted) frame.
        guard count >= 0, count == 0 || rawTouches != nil else { return 0 }
        let touches = rawTouches.map {
            Array(UnsafeBufferPointer(start: $0.assumingMemoryBound(to: MTTouch.self), count: Int(count)))
        } ?? []
        DispatchQueue.main.async {
            let manager = TouchpadManager.shared
            guard manager.isRunning, manager.device == device else { return }
            manager.processFrame(touches, timestamp: timestamp)
        }
        return 0
    }

    private init() {
        enabledSubscription = GestureStore.shared.$isGlobalEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.recognizer.reset()
                self?.lastTriggeredGesture = nil
            }
    }

    public func start() {
        guard !isRunning else { return }
        let bridge = MultitouchBridge.shared
        guard bridge.isAvailable,
              let create = bridge.MTDeviceCreateDefault,
              let register = bridge.MTRegisterContactFrameCallback,
              let start = bridge.MTDeviceStart else { return }
        // Reuse the registered device when restarting, avoiding duplicate callbacks.
        if device == nil {
            guard let created = create() else { return }
            device = created
            register(created, Self.callback)
        }
        recognizer.reset()
        isRunning = true
        start(device, 0)
    }

    public func stop() {
        guard isRunning else { return }
        isRunning = false
        MultitouchBridge.shared.MTDeviceStop?(device)
        recognizer.reset()
        feedbackReset?.cancel()
        lastTriggeredGesture = nil
    }

    private func processFrame(_ touches: [MTTouch], timestamp: Double) {
        guard GestureStore.shared.isGlobalEnabled else {
            recognizer.reset()
            return
        }
        func contact(_ touch: MTTouch) -> GestureRecognizer.Contact {
            .init(id: touch.fingerID, x: touch.normalizedVector.position.x, y: touch.normalizedVector.position.y)
        }
        let touching = touches.filter { $0.state == 3 || $0.state == 4 }.map(contact)
        let ending = touches.filter { $0.state == 5 }.map(contact)
        if let type = recognizer.process(contacts: touching, ending: ending, timestamp: timestamp) {
            triggerGesture(type)
        }
    }

    private func triggerGesture(_ type: GestureType) {
        let store = GestureStore.shared
        guard let gesture = store.gestures.first(where: { $0.gestureType == type && $0.isEnabled }) else { return }
        if store.isHapticFeedbackEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
        lastTriggeredGesture = type
        feedbackReset?.cancel()
        let reset = DispatchWorkItem { [weak self] in self?.lastTriggeredGesture = nil }
        feedbackReset = reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: reset)
        ActionExecutor.shared.execute(gesture: gesture)
    }
}
