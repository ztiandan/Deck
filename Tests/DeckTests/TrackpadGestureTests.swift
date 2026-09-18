import XCTest
@testable import Deck

final class TrackpadGestureTests: XCTestCase {

    // MARK: - 1. Multitouch Support C Bridge Memory Layout Tests
    func testMultitouchMemoryLayout() {
        // Verify Apple MultitouchSupport.framework 64-bit MTTouch layout
        XCTAssertEqual(MemoryLayout<MTPoint>.size, 8, "MTPoint must be 8 bytes (2x Float)")
        XCTAssertEqual(MemoryLayout<MTVector>.size, 16, "MTVector must be 16 bytes (position + velocity)")
        XCTAssertEqual(MemoryLayout<MTTouch>.size, 96, "MTTouch struct size must be exactly 96 bytes")
        XCTAssertEqual(MemoryLayout<MTTouch>.stride, 96, "MTTouch stride must be 96 bytes to avoid indexing corruption across touches")
    }

    // MARK: - 2. GestureModel & Action Types
    func testGestureTypeEnum() {
        let allCases = GestureType.allCases
        XCTAssertEqual(allCases.count, 6)

        // Verify display names
        LocalizationManager.shared.setLanguage(.english)
        XCTAssertEqual(GestureType.tipTapRight2F.displayName, "TipTap Right (2 Fingers)")
        XCTAssertEqual(GestureType.tipTapLeft2F.displayName, "TipTap Left (2 Fingers)")
        XCTAssertEqual(GestureType.tipTapLeft3F.displayName, "TipTap Left (3 Fingers)")
        XCTAssertEqual(GestureType.tipTapRight3F.displayName, "TipTap Right (3 Fingers)")
        XCTAssertEqual(GestureType.fourFingerTap.displayName, "4-Finger Tap")
        XCTAssertEqual(GestureType.threeFingerTap.displayName, "3-Finger Tap")

        // Verify Chinese display names
        LocalizationManager.shared.setLanguage(.chinese)
        XCTAssertEqual(GestureType.tipTapRight2F.displayName, "TipTap Right (双指·右敲)")
        XCTAssertEqual(GestureType.tipTapLeft2F.displayName, "TipTap Left (双指·左敲)")
        XCTAssertEqual(GestureType.tipTapLeft3F.displayName, "TipTap Left (三指·左敲)")
        XCTAssertEqual(GestureType.tipTapRight3F.displayName, "TipTap Right (三指·右敲)")
        XCTAssertEqual(GestureType.fourFingerTap.displayName, "四指同时轻点")
        XCTAssertEqual(GestureType.threeFingerTap.displayName, "三指同时轻点")

        // Restore to English
        LocalizationManager.shared.setLanguage(.english)
    }

    func testGestureActionTypeDecoding() throws {
        // Test standard string decoding
        let jsonShortcut = "\"shortcut\"".data(using: .utf8)!
        let action1 = try JSONDecoder().decode(GestureActionType.self, from: jsonShortcut)
        XCTAssertEqual(action1, .shortcut)

        let jsonCmdClick = "\"cmdClick\"".data(using: .utf8)!
        let action2 = try JSONDecoder().decode(GestureActionType.self, from: jsonCmdClick)
        XCTAssertEqual(action2, .cmdClick)

        let jsonMiddleClick = "\"middleClick\"".data(using: .utf8)!
        let action3 = try JSONDecoder().decode(GestureActionType.self, from: jsonMiddleClick)
        XCTAssertEqual(action3, .middleClick)

        // Test localized legacy string decoding
        let jsonChineseCmd = "\"CMD(⌘) + 点击\"".data(using: .utf8)!
        let action4 = try JSONDecoder().decode(GestureActionType.self, from: jsonChineseCmd)
        XCTAssertEqual(action4, .cmdClick)
    }

    func testTouchpadGestureCodable() throws {
        let gesture = TouchpadGesture(
            gestureType: .tipTapRight2F,
            actionType: .shortcut,
            shortcutDisplay: "⌘ W",
            keyCode: 13,
            modifiers: ["cmd"],
            isEnabled: true,
            notes: "Close tab"
        )

        let encoded = try JSONEncoder().encode(gesture)
        let decoded = try JSONDecoder().decode(TouchpadGesture.self, from: encoded)

        XCTAssertEqual(decoded.id, gesture.id)
        XCTAssertEqual(decoded.gestureType, .tipTapRight2F)
        XCTAssertEqual(decoded.actionType, .shortcut)
        XCTAssertEqual(decoded.shortcutDisplay, "⌘ W")
        XCTAssertEqual(decoded.keyCode, 13)
        XCTAssertEqual(decoded.modifiers, ["cmd"])
        XCTAssertTrue(decoded.isEnabled)
        XCTAssertEqual(decoded.notes, "Close tab")
    }

    // MARK: - 3. GestureStore State & Management
    func testGestureStoreDefaultGestures() {
        let defaults = GestureStore.shared.defaultGestures()
        XCTAssertEqual(defaults.count, 5)

        XCTAssertEqual(defaults[0].gestureType, .tipTapRight2F)
        XCTAssertEqual(defaults[0].shortcutDisplay, "⌘ W")
        XCTAssertEqual(defaults[0].keyCode, 13)

        XCTAssertEqual(defaults[1].gestureType, .tipTapLeft2F)
        XCTAssertEqual(defaults[1].shortcutDisplay, "⌘ R")
        XCTAssertEqual(defaults[1].keyCode, 15)

        XCTAssertEqual(defaults[2].gestureType, .tipTapLeft3F)
        XCTAssertEqual(defaults[2].shortcutDisplay, "^ ←")
        XCTAssertEqual(defaults[2].keyCode, 123)

        XCTAssertEqual(defaults[3].gestureType, .tipTapRight3F)
        XCTAssertEqual(defaults[3].shortcutDisplay, "^ →")
        XCTAssertEqual(defaults[3].keyCode, 124)

        XCTAssertEqual(defaults[4].gestureType, .fourFingerTap)
        XCTAssertEqual(defaults[4].actionType, .cmdClick)
    }

    func testGestureStoreAddToggleRemove() {
        let store = GestureStore.shared
        let originalCount = store.gestures.count

        let testGesture = TouchpadGesture(
            gestureType: .threeFingerTap,
            actionType: .shortcut,
            shortcutDisplay: "⌘ T",
            keyCode: 17,
            modifiers: ["cmd"],
            isEnabled: true,
            notes: "New tab"
        )

        // Add
        store.addGesture(testGesture)
        XCTAssertEqual(store.gestures.count, originalCount + 1)
        XCTAssertTrue(store.gestures.contains(where: { $0.id == testGesture.id }))

        // Toggle
        store.toggleGesture(id: testGesture.id)
        let toggled = store.gestures.first(where: { $0.id == testGesture.id })
        XCTAssertEqual(toggled?.isEnabled, false)

        store.toggleGesture(id: testGesture.id)
        let toggledBack = store.gestures.first(where: { $0.id == testGesture.id })
        XCTAssertEqual(toggledBack?.isEnabled, true)

        // Remove
        store.removeGesture(id: testGesture.id)
        XCTAssertEqual(store.gestures.count, originalCount)
        XCTAssertFalse(store.gestures.contains(where: { $0.id == testGesture.id }))
    }

    func testHapticFeedbackPreference() {
        let store = GestureStore.shared
        let original = store.isHapticFeedbackEnabled

        store.isHapticFeedbackEnabled = false
        XCTAssertFalse(UserDefaults.standard.bool(forKey: "deck_gesture_haptic_feedback"))

        store.isHapticFeedbackEnabled = true
        XCTAssertTrue(UserDefaults.standard.bool(forKey: "deck_gesture_haptic_feedback"))

        store.isHapticFeedbackEnabled = original
    }

    // MARK: - 4. ActionExecutor Key & Modifier Resolution
    func testActionExecutorKeyResolution() {
        // Test fallback resolution when keyCode is 0
        let g1 = TouchpadGesture(gestureType: .tipTapRight2F, shortcutDisplay: "⌘ W")
        XCTAssertEqual(g1.keyCode, 0)

        // Execute should not crash
        XCTAssertNoThrow(ActionExecutor.shared.execute(gesture: g1))

        let g2 = TouchpadGesture(gestureType: .fourFingerTap, actionType: .cmdClick, shortcutDisplay: "CMD(⌘)+Click")
        XCTAssertNoThrow(ActionExecutor.shared.execute(gesture: g2))

        let g3 = TouchpadGesture(gestureType: .fourFingerTap, actionType: .middleClick, shortcutDisplay: "Middle Click")
        XCTAssertNoThrow(ActionExecutor.shared.execute(gesture: g3))
    }
}
