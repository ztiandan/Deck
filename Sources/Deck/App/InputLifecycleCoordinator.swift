import AppKit

/// Keeps hardware listeners aligned with both power state and the active user session.
final class InputLifecycleCoordinator {
    private let notificationCenter: NotificationCenter
    private let onSuspend: () -> Void
    private let onResume: () -> Void
    private var observers: [NSObjectProtocol] = []
    private var observationGeneration = 0
    private var isSleeping = false
    private var isSessionActive = true
    private var isSuspended = false

    init(
        notificationCenter: NotificationCenter = NSWorkspace.shared.notificationCenter,
        onSuspend: @escaping () -> Void,
        onResume: @escaping () -> Void
    ) {
        self.notificationCenter = notificationCenter
        self.onSuspend = onSuspend
        self.onResume = onResume
    }

    func start() {
        guard observers.isEmpty else { return }
        observationGeneration += 1
        let generation = observationGeneration
        let names: [Notification.Name] = [
            NSWorkspace.willSleepNotification,
            NSWorkspace.didWakeNotification,
            NSWorkspace.sessionDidResignActiveNotification,
            NSWorkspace.sessionDidBecomeActiveNotification,
            NSWorkspace.screensDidWakeNotification
        ]
        observers = names.map { name in
            notificationCenter.addObserver(forName: name, object: nil, queue: .main) { [weak self] notification in
                guard let self, self.observationGeneration == generation else { return }
                self.handle(notification.name)
            }
        }
    }

    func stop() {
        // Also invalidate notifications already queued on the main thread.
        observationGeneration += 1
        observers.forEach(notificationCenter.removeObserver)
        observers.removeAll()
        isSleeping = false
        isSessionActive = true
        isSuspended = false
    }

    deinit { stop() }

    private func handle(_ name: Notification.Name) {
        switch name {
        case NSWorkspace.willSleepNotification:
            isSleeping = true
        case NSWorkspace.sessionDidResignActiveNotification:
            isSessionActive = false
        case NSWorkspace.didWakeNotification:
            isSleeping = false
        case NSWorkspace.sessionDidBecomeActiveNotification:
            isSessionActive = true
        case NSWorkspace.screensDidWakeNotification:
            break
        default:
            return
        }

        if isSleeping || !isSessionActive {
            guard !isSuspended else { return }
            isSuspended = true
            onSuspend()
        } else {
            isSuspended = false
            // Recover even if the corresponding sleep notification was missed.
            // Display wake also covers display-only sleep.
            onResume()
        }
    }
}
