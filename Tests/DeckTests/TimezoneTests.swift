import XCTest
@testable import Deck

final class TimezoneTests: IsolatedDeckTestCase {

    func testMajorEconomiesList() {
        let economies = TimezoneDatabase.majorEconomies
        XCTAssertFalse(economies.isEmpty, "Major economies list should not be empty")
        XCTAssertGreaterThanOrEqual(economies.count, 10, "Should include at least 10 major economy regions")

        // 验证关键经济体存在
        let identifiers = Set(economies.map(\.identifier))
        XCTAssertTrue(identifiers.contains("Asia/Shanghai"), "Must include China (Asia/Shanghai)")
        XCTAssertTrue(identifiers.contains("America/New_York"), "Must include US East (America/New_York)")
        XCTAssertTrue(identifiers.contains("America/Los_Angeles"), "Must include US West (America/Los_Angeles)")
        XCTAssertTrue(identifiers.contains("Europe/London"), "Must include UK (Europe/London)")
        XCTAssertTrue(identifiers.contains("Europe/Berlin"), "Must include Germany/EU (Europe/Berlin)")
        XCTAssertTrue(identifiers.contains("Asia/Tokyo"), "Must include Japan (Asia/Tokyo)")
        XCTAssertTrue(identifiers.contains("Asia/Singapore"), "Must include Singapore (Asia/Singapore)")

        for item in economies {
            XCTAssertFalse(item.countryName.isEmpty, "Country name should not be empty for \(item.identifier)")
            XCTAssertFalse(item.cityName.isEmpty, "City name should not be empty for \(item.identifier)")
            XCTAssertFalse(item.flag.isEmpty, "Flag should not be empty for \(item.identifier)")
            XCTAssertNotNil(TimeZone(identifier: item.identifier), "TimeZone identifier \(item.identifier) must be valid in Foundation")
            XCTAssertTrue(item.isMajorEconomy)
        }
    }

    func testAllTimezonesLoading() {
        let all = TimezoneDatabase.allTimezones
        XCTAssertGreaterThanOrEqual(all.count, 400, "Should load all 400+ IANA timezones")

        // 验证去重
        let idSet = Set(all.map(\.identifier))
        XCTAssertEqual(idSet.count, all.count, "Timezone items must have unique identifiers")

        // 验证大洲分类
        let asiaCount = all.filter { $0.region == .asia }.count
        let americasCount = all.filter { $0.region == .americas }.count
        let europeCount = all.filter { $0.region == .europe }.count

        XCTAssertGreaterThan(asiaCount, 0)
        XCTAssertGreaterThan(americasCount, 0)
        XCTAssertGreaterThan(europeCount, 0)
    }

    func testTimezoneFormatting() {
        guard let shanghai = TimezoneDatabase.find(by: "Asia/Shanghai") else {
            XCTFail("Asia/Shanghai not found")
            return
        }

        let time = shanghai.formattedTime()
        XCTAssertEqual(time.count, 5, "Time format should be HH:mm (5 chars)")
        XCTAssertTrue(time.contains(":"), "Time format should contain colon")

        let timeWithSecs = shanghai.formattedTimeWithSeconds()
        XCTAssertEqual(timeWithSecs.count, 8, "Time format should be HH:mm:ss (8 chars)")

        let offset = shanghai.utcOffsetString()
        XCTAssertTrue(offset.hasPrefix("UTC"), "Offset should start with UTC")
        XCTAssertEqual(offset, "UTC+8", "Shanghai offset should be UTC+8")

        let diff = shanghai.relativeTimeDifference(comparedTo: TimeZone(identifier: "Asia/Shanghai")!)
        XCTAssertTrue(diff == "相同时间" || diff == "Same time")
    }

    func testTimezoneDatabaseFind() {
        let ny = TimezoneDatabase.find(by: "America/New_York")
        XCTAssertNotNil(ny)
        XCTAssertEqual(ny?.identifier, "America/New_York")
        XCTAssertEqual(ny?.region, .americas)

        let invalid = TimezoneDatabase.find(by: "Invalid/Nonexistent_Timezone")
        XCTAssertNil(invalid)
    }

    func testTimezoneManager() {
        let manager = TimezoneManager.shared
        manager.refreshCurrentTimezone()

        XCTAssertFalse(manager.currentTimezone.isEmpty)
        XCTAssertFalse(manager.currentCityName.isEmpty)
        XCTAssertFalse(manager.currentTimezoneShort.isEmpty)

        // 验证当前时区项目
        let currentItem = manager.currentItem
        XCTAssertEqual(currentItem.identifier, manager.currentTimezone)

        // 验证时钟显示非空
        XCTAssertFalse(manager.currentFormattedTime.isEmpty)
        XCTAssertFalse(manager.currentFormattedDate.isEmpty)
    }

    func testDeckTabTimezone() {
        let tab = DeckTab.timezone
        XCTAssertEqual(tab.id, "timezone")
        XCTAssertEqual(tab.iconName, "globe")
        XCTAssertTrue(DeckTab.allCases.contains(.timezone))

        LocalizationManager.shared.setLanguage(.english)
        XCTAssertEqual(tab.title, "Timezone")

        LocalizationManager.shared.setLanguage(.chinese)
        XCTAssertEqual(tab.title, "时区切换")

        // 恢复默认语言
        LocalizationManager.shared.setLanguage(.english)
    }
}
