import XCTest
import Combine
@testable import Deck

final class TouchpadRecoveryTests: IsolatedDeckTestCase {
    private final class Input: TouchpadInput {
        var canStart = true
        var handlers: [([MTTouch], Double) -> Void] = []
        var active = false
        var starts = 0

        func start(onFrame: @escaping ([MTTouch], Double) -> Void) -> Bool {
            XCTAssertFalse(active, "The previous device must be stopped before a new registration")
            starts += 1
            handlers.append(onFrame)
            active = canStart
            return active
        }

        func stop() { active = false }
    }

    private final class Scheduler {
        final class Job {
            var cancelled = false
            let action: () -> Void
            init(_ action: @escaping () -> Void) { self.action = action }
        }
        var jobs: [Job] = []
        var pending: [Job] { jobs.filter { !$0.cancelled } }

        func schedule(_ delay: TimeInterval, _ action: @escaping () -> Void) -> AnyCancellable {
            let job = Job(action)
            jobs.append(job)
            return AnyCancellable { job.cancelled = true }
        }
    }

    private func drainFrames() {
        let drained = expectation(description: "Frames delivered to main queue")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 2)
    }

    private func fingers() -> [MTTouch] {
        (1...4).map { id in
            MTTouch(frame: 0, timestamp: 0, pathIndex: 0, state: 4, fingerID: Int32(id), handID: 0,
                    normalizedVector: MTVector(position: MTPoint(x: Float(id) * 0.18, y: 0.5)),
                    zTotal: 0, field9: 0, angle: 0, majorAxis: 0, minorAxis: 0,
                    absoluteVector: MTVector(), field14: 0, field15: 0, zDensity: 0)
        }
    }

    func testRepeatedSleepCyclesRecreateInputAndCancelOldRetries() {
        let input = Input(), scheduler = Scheduler()
        let manager = TouchpadManager(input: input, store: makeGestureStore(), scheduleRetry: scheduler.schedule)
        manager.start()
        manager.start()
        XCTAssertEqual(input.starts, 1)
        for cycle in 1...3 {
            let staleRetry = scheduler.pending.first!
            manager.suspend()
            XCTAssertFalse(manager.isRunning)
            XCTAssertFalse(input.active)
            XCTAssertTrue(scheduler.pending.isEmpty)
            manager.start()
            XCTAssertEqual(input.starts, cycle)
            manager.resume()
            XCTAssertTrue(manager.isRunning)
            XCTAssertEqual(input.starts, cycle + 1)
            staleRetry.action() // Even an already dequeued task must not restart the new session.
            XCTAssertEqual(input.starts, cycle + 1)
            XCTAssertEqual(scheduler.pending.count, 1)
        }
        manager.stop()
        manager.resume()
        XCTAssertFalse(manager.isRunning)
        XCTAssertTrue(scheduler.pending.isEmpty)
        XCTAssertEqual(input.starts, 4)
    }

    func testWakeRetriesUnavailableDeviceUntilFirstFrame() throws {
        let input = Input(), scheduler = Scheduler()
        let manager = TouchpadManager(input: input, store: makeGestureStore(), scheduleRetry: scheduler.schedule)
        input.canStart = false
        manager.start()
        XCTAssertFalse(manager.isRunning)
        input.canStart = true
        try XCTUnwrap(scheduler.pending.first).action()
        XCTAssertTrue(manager.isRunning)
        XCTAssertEqual(input.starts, 2)
        try XCTUnwrap(input.handlers.last)([], 10)
        drainFrames()
        XCTAssertTrue(scheduler.pending.isEmpty, "An empty frame also proves that callbacks are alive")
        manager.stop()
    }

    func testSilentNativeStartIsRetriedForABoundedPeriod() {
        let input = Input(), scheduler = Scheduler()
        let manager = TouchpadManager(input: input, store: makeGestureStore(), scheduleRetry: scheduler.schedule)
        manager.start()
        // Native registration succeeded, but no frames arrived after waking.
        for _ in 0..<10 {
            guard let retry = scheduler.pending.first else { break }
            retry.action()
        }
        XCTAssertEqual(input.starts, 6)
        XCTAssertTrue(scheduler.pending.isEmpty)
        manager.stop()
    }

    func testWakeDiscardsQueuedFramesAndIncompleteGestures() throws {
        let input = Input(), scheduler = Scheduler(), store = makeGestureStore()
        store.isHapticFeedbackEnabled = false
        var gestures: [GestureType] = []
        let manager = TouchpadManager(input: input, store: store, execute: { gestures.append($0.gestureType) },
                                      scheduleRetry: scheduler.schedule)
        manager.start()
        let oldFrame = try XCTUnwrap(input.handlers.last)
        oldFrame(fingers(), 1)
        drainFrames()
        oldFrame([], 1.1) // Queued just before sleep; must not trigger after resume.
        manager.suspend()
        manager.resume()
        let newFrame = try XCTUnwrap(input.handlers.last)
        newFrame([], 1.2)
        drainFrames()
        XCTAssertTrue(gestures.isEmpty)
        XCTAssertNil(manager.lastTriggeredGesture)

        // A late callback from the old device cannot confirm or drive the new stream.
        manager.resume()
        oldFrame(fingers(), 2)
        oldFrame([], 2.1)
        drainFrames()
        XCTAssertTrue(gestures.isEmpty)
        XCTAssertEqual(scheduler.pending.count, 1)
        let currentFrame = try XCTUnwrap(input.handlers.last)
        currentFrame(fingers(), 3)
        currentFrame([], 3.1)
        drainFrames()
        XCTAssertEqual(gestures, [.fourFingerTap])
        manager.stop()
    }

    func testRecoveryPreservesUserDisabledGestures() throws {
        let input = Input(), scheduler = Scheduler(), store = makeGestureStore()
        store.isGlobalEnabled = false
        store.isHapticFeedbackEnabled = false
        var actions = 0
        let manager = TouchpadManager(input: input, store: store, execute: { _ in actions += 1 },
                                      scheduleRetry: scheduler.schedule)
        manager.start()
        manager.suspend()
        manager.resume()
        let frame = try XCTUnwrap(input.handlers.last)
        frame(fingers(), 1)
        frame([], 1.1)
        drainFrames()
        XCTAssertFalse(store.isGlobalEnabled)
        XCTAssertEqual(actions, 0)
        XCTAssertTrue(scheduler.pending.isEmpty)
        manager.stop()
    }
}
