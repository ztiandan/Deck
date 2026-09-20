import XCTest
@testable import Deck

final class LaunchAtLoginTests: IsolatedDeckTestCase {

    func testLaunchAtLoginManagerRefresh() {
        let manager = LaunchAtLoginManager.shared
        manager.refresh()
        // Ensure refresh completes without crashing and initializes isEnabled boolean
        XCTAssertNotNil(manager.isEnabled)
    }

    func testAppConfigShowWindowOnLaunchDefault() {
        let config = AppConfig()
        XCTAssertFalse(config.showWindowOnLaunch, "showWindowOnLaunch should default to false so app starts silently")
    }

    func testAppConfigShowWindowOnLaunchCodable() throws {
        var config = AppConfig()
        config.showWindowOnLaunch = true

        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(AppConfig.self, from: data)

        XCTAssertTrue(decoded.showWindowOnLaunch)
    }
}
