import XCTest
@testable import Deck

/// Store tests must never read or rewrite the user's actual Deck configuration.
class IsolatedDeckTestCase: XCTestCase {
    var testDirectory: URL!
    var testPreferences: UserDefaults!
    private var suiteName: String!
    private var originalLanguage: AppLanguage!
    private var originalLanguagePreference: Any?
    private var originalCallback: (() -> Void)?

    override func setUpWithError() throws {
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        suiteName = "DeckTests.\(UUID().uuidString)"
        testPreferences = UserDefaults(suiteName: suiteName)!
        originalLanguage = LocalizationManager.shared.currentLanguage
        originalLanguagePreference = UserDefaults.standard.object(forKey: "deck_app_language_preference")
        originalCallback = LocalizationManager.shared.onLanguageChanged
        LocalizationManager.shared.onLanguageChanged = nil
    }

    override func tearDownWithError() throws {
        LocalizationManager.shared.onLanguageChanged = nil
        LocalizationManager.shared.currentLanguage = originalLanguage
        UserDefaults.standard.set(originalLanguagePreference, forKey: "deck_app_language_preference")
        LocalizationManager.shared.onLanguageChanged = originalCallback
        ConfigurationIssue.shared.message = nil
        testPreferences.removePersistentDomain(forName: suiteName)
        try FileManager.default.removeItem(at: testDirectory)
    }

    func makeGestureStore() -> GestureStore {
        GestureStore(fileURL: testDirectory.appendingPathComponent("gestures.json"), preferences: testPreferences)
    }
}
