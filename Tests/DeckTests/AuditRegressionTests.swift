import XCTest
import AppKit
@testable import Deck

final class AuditRegressionTests: IsolatedDeckTestCase {
    private func event(_ key: String, code: UInt16 = 8, flags: NSEvent.ModifierFlags = [], repeatKey: Bool = false) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0,
                        windowNumber: 0, context: nil, characters: key, charactersIgnoringModifiers: key,
                        isARepeat: repeatKey, keyCode: code)!
    }

    func testMappingRejectsInvalidAndDuplicateKeysButAllowsEditingItself() {
        let chrome = PaletteItem(key: "c", displayName: "Chrome")
        let space = PaletteItem(key: "Space", displayName: "Last", actionType: .activateLastApp)
        for key in ["", "abc", "cmd+c", "\n", "\t"] {
            XCTAssertEqual(PaletteItem.keyValidationError(key, items: []), .paletteKeyInvalid)
        }
        for key in ["c", "C", " c "] {
            XCTAssertEqual(PaletteItem.keyValidationError(key, items: [chrome]), .paletteKeyDuplicate)
            XCTAssertNil(PaletteItem.keyValidationError(key, excluding: chrome.id, items: [chrome]))
        }
        for key in [" ", "Space", "space", "␣", "空格"] {
            XCTAssertEqual(PaletteItem.keyValidationError(key, items: [space]), .paletteKeyDuplicate)
        }
        XCTAssertNil(PaletteItem.keyValidationError("|", items: [chrome, space]))
    }

    func testSpaceFallbackNeverConsumesModifiedSpaceOrRepeatedKeys() {
        let last = PaletteItem(key: "|", displayName: "Last", actionType: .activateLastApp)
        XCTAssertEqual(PaletteItem.action(for: event(" ", code: 49), items: [last]), last)
        for flags: NSEvent.ModifierFlags in [.command, .control, .option] {
            XCTAssertNil(PaletteItem.action(for: event(" ", code: 49, flags: flags), items: [last]))
            XCTAssertNil(PaletteItem.action(for: event("|", flags: flags), items: [last]))
        }
        XCTAssertNil(PaletteItem.action(for: event("|", repeatKey: true), items: [last]))
        let explicit = PaletteItem(key: "Space", displayName: "Finder")
        XCTAssertEqual(PaletteItem.action(for: event(" ", code: 49), items: [last, explicit]), explicit)
    }

    func testGlobalTriggerRequiresUnmodifiedConfiguredKey() throws {
        let key = try XCTUnwrap(CGEvent(keyboardEventSource: nil, virtualKey: 79, keyDown: true))
        key.flags = []
        XCTAssertTrue(HotKeyManager.isTrigger(key, keyCode: 79))
        XCTAssertFalse(HotKeyManager.isTrigger(key, keyCode: 80))
        for flags: CGEventFlags in [.maskCommand, .maskShift, .maskControl, .maskAlternate] {
            key.flags = flags
            XCTAssertFalse(HotKeyManager.isTrigger(key, keyCode: 79))
        }
    }

    func testExplicitApplicationIdentityNeverUsesDisplayNameFallback() {
        XCTAssertNil(AppSwitcher.fallbackName(bundleIdentifier: "com.example.app", appPath: nil, displayName: "Chrome"))
        XCTAssertNil(AppSwitcher.fallbackName(bundleIdentifier: nil, appPath: "/Missing.app", displayName: "Chrome"))
        XCTAssertNil(AppSwitcher.fallbackName(bundleIdentifier: nil, appPath: nil, displayName: "  "))
        XCTAssertEqual(AppSwitcher.fallbackName(bundleIdentifier: nil, appPath: nil, displayName: " Activate Chrome "), "Chrome")
    }

    func testCorruptConfigurationsArePreservedBeforeRecoverySave() throws {
        for name in ["palette.json", "hosts.json", "gestures.json"] {
            let url = testDirectory.appendingPathComponent(name)
            let corrupt = Data("{broken user configuration".utf8)
            try corrupt.write(to: url)
            switch name {
            case "palette.json":
                let store = ConfigStore(fileURL: url)
                XCTAssertEqual(try Data(contentsOf: url), corrupt)
                store.save()
            case "hosts.json":
                let store = HostsStore(fileURL: url)
                XCTAssertEqual(try Data(contentsOf: url), corrupt)
                store.save()
            default:
                let store = GestureStore(fileURL: url, preferences: testPreferences)
                XCTAssertEqual(try Data(contentsOf: url), corrupt)
                store.save()
            }
            let backups = try FileManager.default.contentsOfDirectory(at: testDirectory, includingPropertiesForKeys: nil)
                .filter { $0.lastPathComponent.hasPrefix(name + ".recovery-") }
            XCTAssertEqual(backups.count, 1)
            XCTAssertEqual(try Data(contentsOf: XCTUnwrap(backups.first)), corrupt)
        }
    }

    func testDraftsSurviveReloadSwitchingAndFailedApply() throws {
        let url = testDirectory.appendingPathComponent("hosts.json")
        let store = HostsStore(fileURL: url)
        let first = store.addProfile(title: "First"), second = store.addProfile(title: "Second")
        store.updateDraft(id: first.id, content: "127.0.0.1 first.test")
        store.updateDraft(id: second.id, content: "::1 second.test")
        store.saveDrafts()
        let reloaded = HostsStore(fileURL: url)
        XCTAssertEqual(reloaded.editingContent(for: first), "127.0.0.1 first.test")
        XCTAssertEqual(reloaded.editingContent(for: second), "::1 second.test")
        let manager = HostsManager(hostsURL: testDirectory.appendingPathComponent("missing"), authorizeWrite: { XCTFail() }, refreshDNS: {})
        var edited = first
        edited.content = reloaded.editingContent(for: first)
        XCTAssertFalse(reloaded.applyProfile(edited, manager: manager))
        XCTAssertEqual(reloaded.drafts[first.id], edited.content)
        reloaded.updateDraft(id: first.id, content: first.content)
        reloaded.saveDrafts()
        XCTAssertNil(HostsStore(fileURL: url).drafts[first.id])
    }

    func testConfigSaveFailureDoesNotDiscardAppliedDraft() throws {
        let url = testDirectory.appendingPathComponent("hosts.json")
        let store = HostsStore(fileURL: url)
        var profile = store.addProfile(title: "Draft")
        profile.content = "127.0.0.1 draft.test"
        store.updateDraft(id: profile.id, content: profile.content)
        store.saveDrafts()
        let system = testDirectory.appendingPathComponent("system-hosts")
        try Data().write(to: system)
        try FileManager.default.removeItem(at: url)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
        let manager = HostsManager(hostsURL: system, authorizeWrite: { XCTFail() }, refreshDNS: {})
        XCTAssertFalse(store.applyProfile(profile, manager: manager))
        XCTAssertEqual(store.drafts[profile.id], profile.content)
        XCTAssertNotNil(ConfigurationIssue.shared.message)
    }

    func testGesturePreferencesAndEditsSurviveReload() {
        let store = makeGestureStore()
        store.isGlobalEnabled = false
        store.isHapticFeedbackEnabled = false
        var first = store.gestures[0]
        first.shortcutDisplay = "⌘ T"
        first.notes = "Custom note"
        store.updateGesture(first)
        let reloaded = makeGestureStore()
        XCTAssertFalse(reloaded.isGlobalEnabled)
        XCTAssertFalse(reloaded.isHapticFeedbackEnabled)
        XCTAssertEqual(reloaded.gestures[0].shortcutDisplay, "⌘ T")
        XCTAssertEqual(reloaded.gestures[0].notes, "Custom note")
    }

    func testUnsupportedGestureActionIsNotSilentlyConvertedToKeyboardInput() {
        XCTAssertThrowsError(try JSONDecoder().decode(GestureActionType.self, from: Data("\"futureAction\"".utf8)))
    }

    func testAddingEnablingAndEditingGestureMakesNewActionEffective() {
        let store = makeGestureStore()
        let original = store.gestures[0]
        var replacement = TouchpadGesture(gestureType: original.gestureType, shortcutDisplay: "⌘ T")
        store.addGesture(replacement)
        XCTAssertEqual(store.gestures.filter { $0.gestureType == original.gestureType && $0.isEnabled }.map(\.id), [replacement.id])
        store.toggleGesture(id: original.id)
        XCTAssertEqual(store.gestures.filter { $0.gestureType == original.gestureType && $0.isEnabled }.map(\.id), [original.id])
        replacement.gestureType = .tipTapLeft2F
        replacement.isEnabled = true
        store.updateGesture(replacement)
        XCTAssertEqual(store.gestures.filter { $0.gestureType == .tipTapLeft2F && $0.isEnabled }.map(\.id), [replacement.id])
        XCTAssertEqual(makeGestureStore().gestures, store.gestures)
    }

    func testResolutionAcceptsAllConfiguredAddressesAndAliases() throws {
        let content = "127.0.0.1 localhost\n192.0.2.1 app.test alias.test\n2001:db8::1 APP.TEST\n"
        let result = try XCTUnwrap(HostsResolution.check(content: content, resolve: { _ in ["192.0.2.1", "2001:db8::1"] }))
        XCTAssertTrue(result.matches)
        XCTAssertFalse(result.partiallyMatches)
        let mixed = try XCTUnwrap(HostsResolution.check(content: content, resolve: { _ in ["192.0.2.1", "198.18.0.1"] }))
        XCTAssertFalse(mixed.matches)
        XCTAssertTrue(mixed.partiallyMatches)
    }

    func testDemoProfilesAreInactiveUntilExplicitlyEnabled() {
        XCTAssertTrue(HostsConfig.default.profiles.filter { $0.groupId != nil }.allSatisfy { !$0.isEnabled })
    }

    func testFolderCollapseRemovalAndNonexclusiveProfilesPersist() throws {
        let url = testDirectory.appendingPathComponent("hosts.json")
        let store = HostsStore(fileURL: url)
        store.config.exclusiveInGroup = false
        let group = store.addGroup(title: "Independent", isExclusive: false)
        let first = store.addProfile(title: "First", groupId: group.id)
        let second = store.addProfile(title: "Second", groupId: group.id)
        XCTAssertTrue(store.toggleProfile(id: first.id, applyToSystem: false))
        XCTAssertTrue(store.toggleProfile(id: second.id, applyToSystem: false))
        XCTAssertEqual(store.config.profiles.filter { $0.groupId == group.id && $0.isEnabled }.count, 2)
        store.toggleGroupExpanded(id: group.id)
        XCTAssertEqual(HostsStore(fileURL: url).config.groups.first { $0.id == group.id }?.isExpanded, false)
        store.deleteGroup(id: group.id)
        let reloaded = HostsStore(fileURL: url)
        XCTAssertFalse(reloaded.config.groups.contains { $0.id == group.id })
        for id in [first.id, second.id] {
            let profile = try XCTUnwrap(reloaded.config.profiles.first { $0.id == id })
            XCTAssertNil(profile.groupId)
            XCTAssertTrue(profile.isEnabled)
        }
    }

    func testGlobalExclusivitySwitchCanDisableExclusiveGroupBehavior() {
        let store = HostsStore(fileURL: testDirectory.appendingPathComponent("hosts.json"))
        let group = store.addGroup(title: "Environments", isExclusive: true)
        let first = store.addProfile(title: "First", groupId: group.id)
        let second = store.addProfile(title: "Second", groupId: group.id)
        store.config.exclusiveInGroup = false
        XCTAssertTrue(store.toggleProfile(id: first.id, applyToSystem: false))
        XCTAssertTrue(store.toggleProfile(id: second.id, applyToSystem: false))
        XCTAssertEqual(store.config.profiles.filter { $0.groupId == group.id && $0.isEnabled }.count, 2)
        store.config.exclusiveInGroup = true
        XCTAssertTrue(store.toggleProfile(id: second.id, applyToSystem: false))
        XCTAssertTrue(store.toggleProfile(id: second.id, applyToSystem: false))
        XCTAssertEqual(store.config.profiles.filter { $0.groupId == group.id && $0.isEnabled }.map(\.id), [second.id])
    }

    func testConfigurationCreatesMissingParentAndRoundTrips() throws {
        let url = testDirectory.appendingPathComponent("new/subdirectory/config.json")
        let store = ConfigStore(fileURL: url)
        store.config.themeMode = .dark
        store.config.showAtCursor = true
        store.save()
        let reloaded = ConfigStore(fileURL: url)
        XCTAssertEqual(reloaded.config.themeMode, .dark)
        XCTAssertTrue(reloaded.config.showAtCursor)
        XCTAssertEqual(reloaded.config.items, store.config.items)
    }
}
