import XCTest
@testable import Deck

final class LocalizationTests: XCTestCase {

    func testLocalizationCoverage() {
        let manager = LocalizationManager.shared
        let allKeys = L10nKey.allCases

        XCTAssertFalse(allKeys.isEmpty)

        // 1. Verify English translation completeness
        manager.setLanguage(.english)
        for key in allKeys {
            let translation = manager.t(key)
            XCTAssertFalse(translation.isEmpty, "Missing English translation for \(key.rawValue)")
            // Verify it was translated (i.e. not falling back to the raw enum identifier)
            XCTAssertNotEqual(translation, key.rawValue, "English translation for \(key.rawValue) is untranslated")
        }

        // 2. Verify Chinese translation completeness
        manager.setLanguage(.chinese)
        for key in allKeys {
            let translation = manager.t(key)
            XCTAssertFalse(translation.isEmpty, "Missing Chinese translation for \(key.rawValue)")
            XCTAssertNotEqual(translation, key.rawValue, "Chinese translation for \(key.rawValue) is untranslated")
        }

        // Restore English
        manager.setLanguage(.english)
    }

    func testLanguageSwitchCallback() {
        let manager = LocalizationManager.shared
        var callbackFired = false

        manager.onLanguageChanged = {
            callbackFired = true
        }

        manager.setLanguage(.chinese)
        XCTAssertTrue(callbackFired)
        XCTAssertEqual(manager.currentLanguage, .chinese)

        callbackFired = false
        manager.setLanguage(.english)
        XCTAssertTrue(callbackFired)
        XCTAssertEqual(manager.currentLanguage, .english)

        manager.onLanguageChanged = nil
    }

    func testAppLanguageEnum() {
        XCTAssertEqual(AppLanguage.english.rawValue, "en")
        XCTAssertEqual(AppLanguage.chinese.rawValue, "zh-Hans")
        XCTAssertEqual(AppLanguage.english.displayName, "English (Default)")
        XCTAssertEqual(AppLanguage.chinese.displayName, "简体中文 (Chinese)")
    }
}
