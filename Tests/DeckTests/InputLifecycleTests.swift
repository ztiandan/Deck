import AppKit
import XCTest
@testable import Deck

final class InputLifecycleTests: XCTestCase {
    func testSleepSuspendsOnceAndWakeResumes() {
        let center = NotificationCenter()
        var calls: [String] = []
        let coordinator = InputLifecycleCoordinator(
            notificationCenter: center,
            onSuspend: { calls.append("suspend") },
            onResume: { calls.append("resume") }
        )
        coordinator.start()
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        XCTAssertEqual(calls, ["suspend"])
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertEqual(calls, ["suspend", "resume"])
    }

    func testWakeWaitsForUserSessionToBecomeActive() {
        let center = NotificationCenter()
        var calls: [String] = []
        let coordinator = InputLifecycleCoordinator(
            notificationCenter: center,
            onSuspend: { calls.append("suspend") },
            onResume: { calls.append("resume") }
        )
        coordinator.start()
        center.post(name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        center.post(name: NSWorkspace.screensDidWakeNotification, object: nil)
        XCTAssertEqual(calls, ["suspend"])
        center.post(name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        XCTAssertEqual(calls, ["suspend", "resume"])
    }

    func testSessionActivationAndDisplayWakeDoNotResumeWhileSleeping() {
        let center = NotificationCenter()
        var calls: [String] = []
        let coordinator = InputLifecycleCoordinator(
            notificationCenter: center,
            onSuspend: { calls.append("suspend") },
            onResume: { calls.append("resume") }
        )
        coordinator.start()
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        center.post(name: NSWorkspace.sessionDidResignActiveNotification, object: nil)
        center.post(name: NSWorkspace.sessionDidBecomeActiveNotification, object: nil)
        center.post(name: NSWorkspace.screensDidWakeNotification, object: nil)
        XCTAssertEqual(calls, ["suspend"])
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertEqual(calls, ["suspend", "resume"])
    }

    func testDisplayWakeRecoversWithoutASleepNotification() {
        let center = NotificationCenter()
        var resumeCount = 0
        let coordinator = InputLifecycleCoordinator(
            notificationCenter: center,
            onSuspend: { XCTFail("Display wake should not suspend the listeners") },
            onResume: { resumeCount += 1 }
        )
        coordinator.start()
        center.post(name: NSWorkspace.screensDidWakeNotification, object: nil)
        XCTAssertEqual(resumeCount, 1)
    }

    func testDuplicateStartAndStopDoNotLeaveObserversBehind() {
        let center = NotificationCenter()
        var calls: [String] = []
        let coordinator = InputLifecycleCoordinator(
            notificationCenter: center,
            onSuspend: { calls.append("suspend") },
            onResume: { calls.append("resume") }
        )
        coordinator.start()
        coordinator.start()
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertEqual(calls, ["suspend", "resume"])
        coordinator.stop()
        coordinator.stop()
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        center.post(name: NSWorkspace.screensDidWakeNotification, object: nil)
        XCTAssertEqual(calls, ["suspend", "resume"])
        coordinator.start()
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertEqual(calls, ["suspend", "resume", "suspend", "resume"])
    }

    func testDeinitializationRemovesObservers() {
        let center = NotificationCenter()
        var calls = 0
        var coordinator: InputLifecycleCoordinator? = InputLifecycleCoordinator(
            notificationCenter: center,
            onSuspend: { calls += 1 },
            onResume: { calls += 1 }
        )
        coordinator?.start()
        weak var weakCoordinator = coordinator
        coordinator = nil
        XCTAssertNil(weakCoordinator)
        center.post(name: NSWorkspace.willSleepNotification, object: nil)
        center.post(name: NSWorkspace.didWakeNotification, object: nil)
        XCTAssertEqual(calls, 0)
    }
}
