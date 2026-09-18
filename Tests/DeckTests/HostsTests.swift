import XCTest
@testable import Deck

final class HostsTests: IsolatedDeckTestCase {

    // MARK: - 1. HostsModel & Configuration
    func testHostsProfileCodable() throws {
        let profile = HostsProfile(
            title: "Staging",
            content: "192.168.1.100 staging.example.com",
            isEnabled: true,
            groupId: nil,
            order: 3
        )

        let encoded = try JSONEncoder().encode(profile)
        let decoded = try JSONDecoder().decode(HostsProfile.self, from: encoded)

        XCTAssertEqual(decoded.id, profile.id)
        XCTAssertEqual(decoded.title, "Staging")
        XCTAssertEqual(decoded.content, "192.168.1.100 staging.example.com")
        XCTAssertTrue(decoded.isEnabled)
        XCTAssertNil(decoded.groupId)
        XCTAssertEqual(decoded.order, 3)
    }

    func testHostsGroupCodable() throws {
        let group = HostsGroup(title: "Work Projects", isExpanded: true, isExclusive: true)
        let encoded = try JSONEncoder().encode(group)
        let decoded = try JSONDecoder().decode(HostsGroup.self, from: encoded)

        XCTAssertEqual(decoded.id, group.id)
        XCTAssertEqual(decoded.title, "Work Projects")
        XCTAssertTrue(decoded.isExpanded)
        XCTAssertTrue(decoded.isExclusive)
    }

    func testDefaultHostsConfig() {
        let config = HostsConfig.default
        XCTAssertFalse(config.profiles.isEmpty)
        XCTAssertFalse(config.groups.isEmpty)

        // Default profile should be enabled
        let defaultProfile = config.profiles.first(where: { $0.title == "Default" })
        XCTAssertNotNil(defaultProfile)
        XCTAssertTrue(defaultProfile?.isEnabled ?? false)

        // Demo group should exist
        let demoGroup = config.groups.first(where: { $0.title == "Demo Domain" })
        XCTAssertNotNil(demoGroup)
        XCTAssertTrue(demoGroup?.isExclusive ?? false)
    }

    // MARK: - 2. HostsStore Group Mutual Exclusivity
    func testGroupExclusiveToggle() {
        let store = HostsStore(fileURL: testDirectory.appendingPathComponent("hosts.json"))
        let originalConfig = store.config

        // Create an exclusive group with two profiles
        let group = store.addGroup(title: "Test Exclusive Group", isExclusive: true)
        let p1 = store.addProfile(title: "Env A", content: "127.0.0.1 a.test", groupId: group.id)
        let p2 = store.addProfile(title: "Env B", content: "127.0.0.1 b.test", groupId: group.id)

        // Enable p1
        if !store.config.profiles.first(where: { $0.id == p1.id })!.isEnabled {
            store.toggleProfile(id: p1.id, applyToSystem: false)
        }

        XCTAssertTrue(store.config.profiles.first(where: { $0.id == p1.id })!.isEnabled)
        XCTAssertFalse(store.config.profiles.first(where: { $0.id == p2.id })!.isEnabled)

        // Enabling p2 should automatically disable p1 due to exclusivity
        store.toggleProfile(id: p2.id, applyToSystem: false)

        XCTAssertFalse(store.config.profiles.first(where: { $0.id == p1.id })!.isEnabled, "p1 must be disabled when p2 is enabled in exclusive group")
        XCTAssertTrue(store.config.profiles.first(where: { $0.id == p2.id })!.isEnabled, "p2 must be enabled")

        // Cleanup
        store.deleteProfile(id: p1.id, applyToSystem: false)
        store.deleteProfile(id: p2.id, applyToSystem: false)
        store.deleteGroup(id: group.id)
        store.config = originalConfig
        store.save()
    }

    // MARK: - 3. HostsManager Merge Generation
    func testGenerateMergedContent() {
        let config = HostsConfig.default
        let content = HostsManager.generateMergedContent(config: config)
        XCTAssertFalse(content.isEmpty)

        // If default profile is active, it should contain localhost
        if config.profiles.contains(where: { $0.isEnabled && $0.content.contains("localhost") }) {
            XCTAssertTrue(content.contains("localhost"))
        }
    }
}
