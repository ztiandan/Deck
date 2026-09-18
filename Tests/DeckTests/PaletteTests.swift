import XCTest
import AppKit
@testable import Deck

final class PaletteTests: IsolatedDeckTestCase {

    // MARK: - 1. PaletteItem Tests
    func testPaletteItemDisplayKey() {
        // Space variations
        let spaceItem1 = PaletteItem(key: " ", displayName: "Last App", actionType: .activateLastApp)
        XCTAssertEqual(spaceItem1.displayKey, "Space")

        let spaceItem2 = PaletteItem(key: "space", displayName: "Last App", actionType: .activateLastApp)
        XCTAssertEqual(spaceItem2.displayKey, "Space")

        let spaceItem3 = PaletteItem(key: "Space", displayName: "Last App", actionType: .activateLastApp)
        XCTAssertEqual(spaceItem3.displayKey, "Space")

        let spaceItem4 = PaletteItem(key: "␣", displayName: "Last App", actionType: .activateLastApp)
        XCTAssertEqual(spaceItem4.displayKey, "Space")

        let spaceItem5 = PaletteItem(key: "空格", displayName: "Last App", actionType: .activateLastApp)
        XCTAssertEqual(spaceItem5.displayKey, "Space")

        // Normal letter keys
        let letterItem = PaletteItem(key: "c", displayName: "Chrome")
        XCTAssertEqual(letterItem.displayKey, "c")

        let symbolItem = PaletteItem(key: "|", displayName: "Switch")
        XCTAssertEqual(symbolItem.displayKey, "|")
    }

    func testPaletteItemEventMatching() {
        let spaceItem = PaletteItem(key: "Space", displayName: "Last App", actionType: .activateLastApp)
        let chromeItem = PaletteItem(key: "c", displayName: "Chrome")

        // 1. Simulate Space Key (keyCode 49)
        let spaceEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: " ",
            charactersIgnoringModifiers: " ",
            isARepeat: false,
            keyCode: 49
        )!

        XCTAssertTrue(spaceItem.matches(event: spaceEvent), "Space item must match keyCode 49")
        XCTAssertFalse(chromeItem.matches(event: spaceEvent), "Chrome item must not match Space key")

        // 2. Simulate 'c' Key (keyCode 8)
        let cEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "c",
            charactersIgnoringModifiers: "c",
            isARepeat: false,
            keyCode: 8
        )!

        XCTAssertTrue(chromeItem.matches(event: cEvent), "Chrome item must match 'c'")
        XCTAssertFalse(spaceItem.matches(event: cEvent), "Space item must not match 'c'")

        // 3. Simulate uppercase 'C'
        let upperCEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: .zero,
            modifierFlags: [.shift],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "C",
            charactersIgnoringModifiers: "c",
            isARepeat: false,
            keyCode: 8
        )!

        XCTAssertTrue(chromeItem.matches(event: upperCEvent), "Chrome item should match case-insensitively")
    }

    func testPaletteItemCodable() throws {
        let item = PaletteItem(
            key: "v",
            displayName: "VS Code",
            actionType: .activateApp,
            bundleIdentifier: "com.microsoft.VSCode",
            appPath: "/Applications/Visual Studio Code.app"
        )

        let encoded = try JSONEncoder().encode(item)
        let decoded = try JSONDecoder().decode(PaletteItem.self, from: encoded)

        XCTAssertEqual(decoded.id, item.id)
        XCTAssertEqual(decoded.key, "v")
        XCTAssertEqual(decoded.displayName, "VS Code")
        XCTAssertEqual(decoded.actionType, .activateApp)
        XCTAssertEqual(decoded.bundleIdentifier, "com.microsoft.VSCode")
        XCTAssertEqual(decoded.appPath, "/Applications/Visual Studio Code.app")
    }

    func testPaletteItemIconFallback() {
        let lastAppItem = PaletteItem(key: "|", displayName: "Last", actionType: .activateLastApp)
        let icon1 = lastAppItem.icon()
        XCTAssertNotNil(icon1)

        let customItem = PaletteItem(key: "z", displayName: "NonExistentApp", bundleIdentifier: "com.nonexistent.app")
        let icon2 = customItem.icon()
        XCTAssertNotNil(icon2)
    }

    // MARK: - 2. ConfigStore & AppConfig Tests
    func testDefaultAppConfig() {
        let config = AppConfig.default
        XCTAssertEqual(config.triggerKeyCode, 79) // F18
        XCTAssertEqual(config.triggerKeyName, "F18")
        XCTAssertFalse(config.items.isEmpty)

        // Verify default contains activateLastApp
        XCTAssertTrue(config.items.contains(where: { $0.actionType == .activateLastApp }))

        // Verify common apps exist
        XCTAssertTrue(config.items.contains(where: { $0.key == "c" }))
        XCTAssertTrue(config.items.contains(where: { $0.key == "v" }))
        XCTAssertTrue(config.items.contains(where: { $0.key == "f" }))
    }

    func testThemeMode() {
        XCTAssertEqual(AppThemeMode.light.rawValue, "light")
        XCTAssertEqual(AppThemeMode.dark.rawValue, "dark")
        XCTAssertEqual(AppThemeMode.system.rawValue, "system")

        LocalizationManager.shared.setLanguage(.english)
        XCTAssertFalse(AppThemeMode.light.title.isEmpty)
        XCTAssertFalse(AppThemeMode.dark.title.isEmpty)
        XCTAssertFalse(AppThemeMode.system.title.isEmpty)
    }
}
