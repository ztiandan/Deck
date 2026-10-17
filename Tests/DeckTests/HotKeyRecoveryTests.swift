import XCTest
import CoreGraphics
@testable import Deck

final class HotKeyRecoveryTests: XCTestCase {
    private final class FakeTap: HotKeyEventTap {
        var isValid = true
        var isEnabled = false
        var allowsEnabling = true
        var invalidationCount = 0

        func setEnabled(_ enabled: Bool) {
            isEnabled = isValid && enabled && allowsEnabling
        }

        func invalidate() {
            invalidationCount += 1
            isValid = false
            isEnabled = false
        }
    }

    private final class Harness {
        var trusted = true
        var failsCreation = false
        var creationAttempts = 0
        var taps: [FakeTap] = []

        func makeManager() -> HotKeyManager {
            HotKeyManager(accessibilityCheck: { _ in self.trusted }, makeEventTap: { _, _ in
                self.creationAttempts += 1
                guard !self.failsCreation else { return nil }
                let tap = FakeTap()
                self.taps.append(tap)
                return tap
            })
        }
    }

    func testWakeReplacesOldTapAndRepeatedSuspendDoesNotCreateOne() throws {
        let harness = Harness()
        let manager = harness.makeManager()
        manager.startPollingAccessibility()
        defer { manager.stopPollingAccessibility() }
        let oldTap = try XCTUnwrap(harness.taps.first)

        manager.suspend()
        manager.suspend()
        manager.refreshListening()
        manager.restartListening()
        XCTAssertFalse(manager.isListening)
        XCTAssertEqual(oldTap.invalidationCount, 1)
        XCTAssertEqual(harness.creationAttempts, 1)

        manager.resume()
        XCTAssertTrue(manager.isListening)
        XCTAssertEqual(harness.taps.count, 2)
        XCTAssertFalse(oldTap.isValid)
    }

    func testPollingReenablesSilentlyDisabledTap() throws {
        let harness = Harness()
        let manager = harness.makeManager()
        manager.startListening()
        let tap = try XCTUnwrap(harness.taps.first)
        tap.isEnabled = false
        XCTAssertTrue(manager.isListening, "The published flag can lag WindowServer state.")

        manager.refreshListening()
        XCTAssertTrue(tap.isEnabled)
        XCTAssertTrue(manager.isListening)
        XCTAssertEqual(harness.creationAttempts, 1)
    }

    func testPollingReplacesInvalidTap() throws {
        let harness = Harness()
        let manager = harness.makeManager()
        manager.startListening()
        let oldTap = try XCTUnwrap(harness.taps.first)
        oldTap.isValid = false

        manager.refreshListening()
        XCTAssertTrue(manager.isListening)
        XCTAssertEqual(harness.creationAttempts, 2)
        XCTAssertEqual(oldTap.invalidationCount, 1)
    }

    func testPollingReplacesTapThatCannotBeReenabled() throws {
        let harness = Harness()
        let manager = harness.makeManager()
        manager.startListening()
        let oldTap = try XCTUnwrap(harness.taps.first)
        oldTap.isEnabled = false
        oldTap.allowsEnabling = false

        manager.refreshListening()
        XCTAssertTrue(manager.isListening)
        XCTAssertEqual(harness.creationAttempts, 2)
        XCTAssertFalse(oldTap.isValid)
    }

    func testFailedWakeCreationIsRetriedOnNextPoll() {
        let harness = Harness()
        let manager = harness.makeManager()
        manager.startListening()
        manager.suspend()
        harness.failsCreation = true
        manager.resume()
        defer { manager.stopPollingAccessibility() }
        XCTAssertFalse(manager.isListening)

        harness.failsCreation = false
        manager.refreshListening()
        XCTAssertTrue(manager.isListening)
        XCTAssertEqual(harness.taps.count, 2)
    }

    func testPermissionRevocationStopsTapAndGrantRestoresIt() throws {
        let harness = Harness()
        let manager = harness.makeManager()
        manager.startListening()
        let oldTap = try XCTUnwrap(harness.taps.first)
        harness.trusted = false
        manager.refreshListening()
        XCTAssertFalse(manager.isListening)
        XCTAssertFalse(manager.isAccessibilityGranted)
        XCTAssertFalse(oldTap.isValid)

        harness.trusted = true
        manager.refreshListening()
        XCTAssertTrue(manager.isListening)
        XCTAssertTrue(manager.isAccessibilityGranted)
        XCTAssertEqual(harness.taps.count, 2)
    }
}
