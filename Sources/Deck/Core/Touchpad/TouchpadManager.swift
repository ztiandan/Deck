import Foundation
import AppKit
import Combine

public class TouchpadManager: ObservableObject {
    public static let shared = TouchpadManager()

    @Published public var isRunning = false
    @Published public var lastTriggeredGesture: GestureType?

    private let input: TouchpadInput
    private let store: GestureStore
    private let execute: (TouchpadGesture) -> Void
    private let scheduleRetry: (TimeInterval, @escaping () -> Void) -> AnyCancellable
    private var wantsRunning = false
    private var isSuspended = false
    private var generation: UInt64 = 0
    private var recoveryRetry: AnyCancellable?
    private var recognizer = GestureRecognizer()
    private var enabledSubscription: AnyCancellable?
    private var feedbackReset: DispatchWorkItem?

    init(input: TouchpadInput = MultitouchInput(), store: GestureStore = .shared,
         execute: @escaping (TouchpadGesture) -> Void = { ActionExecutor.shared.execute(gesture: $0) },
         scheduleRetry: @escaping (TimeInterval, @escaping () -> Void) -> AnyCancellable = { delay, action in
             let work = DispatchWorkItem(block: action)
             DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
             return AnyCancellable { work.cancel() }
         }) {
        self.input = input
        self.store = store
        self.execute = execute
        self.scheduleRetry = scheduleRetry
        enabledSubscription = store.$isGlobalEnabled
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.recognizer.reset()
                self?.lastTriggeredGesture = nil
            }
    }

    public func start() {
        wantsRunning = true
        guard !isSuspended, !isRunning, recoveryRetry == nil else { return }
        beginRecovery()
    }

    public func stop() {
        wantsRunning = false
        stopInput()
    }

    public func suspend() {
        isSuspended = true
        stopInput()
    }

    public func resume() {
        isSuspended = false
        guard wantsRunning else { return }
        beginRecovery()
    }

    private func beginRecovery() {
        attemptStart(retryDelays: [0.5, 1, 2, 4, 8])
    }

    private func attemptStart(retryDelays: [TimeInterval]) {
        stopInput()
        guard wantsRunning, !isSuspended else { return }
        let currentGeneration = generation
        isRunning = input.start { [weak self] touches, timestamp in
            DispatchQueue.main.async {
                guard let self, self.isRunning, self.generation == currentGeneration else { return }
                // The first frame confirms the connection, including an empty frame.
                self.recoveryRetry = nil
                self.processFrame(touches, timestamp: timestamp)
            }
        }
        // A successful native start can still be silent while the hardware wakes.
        // Retry for a bounded period, stopping as soon as real frames arrive.
        guard let delay = retryDelays.first else { return }
        recoveryRetry = scheduleRetry(delay) { [weak self] in
            guard let self, self.generation == currentGeneration,
                  self.wantsRunning, !self.isSuspended else { return }
            self.attemptStart(retryDelays: Array(retryDelays.dropFirst()))
        }
    }

    private func stopInput() {
        generation &+= 1
        recoveryRetry = nil
        isRunning = false
        input.stop()
        recognizer.reset()
        feedbackReset?.cancel()
        feedbackReset = nil
        lastTriggeredGesture = nil
    }

    private func processFrame(_ touches: [MTTouch], timestamp: Double) {
        guard store.isGlobalEnabled else {
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
        guard let gesture = store.gestures.first(where: { $0.gestureType == type && $0.isEnabled }) else { return }
        if store.isHapticFeedbackEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
        lastTriggeredGesture = type
        feedbackReset?.cancel()
        let reset = DispatchWorkItem { [weak self] in self?.lastTriggeredGesture = nil }
        feedbackReset = reset
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: reset)
        execute(gesture)
    }

    deinit {
        recoveryRetry?.cancel()
        feedbackReset?.cancel()
        input.stop()
    }
}
