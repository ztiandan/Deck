import XCTest
import Darwin
@testable import Deck

final class HostsApplyTests: XCTestCase {
    private var directory: URL!
    private var hosts: URL { directory.appendingPathComponent("hosts") }
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("127.0.0.1 localhost\n".utf8).write(to: hosts)
    }
    override func tearDownWithError() throws {
        chmod(directory.path, 0o700)
        try FileManager.default.removeItem(at: directory)
    }
    private func config(_ content: String = "8.8.8.8 test.example.com") -> HostsConfig {
        var config = HostsConfig()
        config.profiles = [HostsProfile(title: "Test", content: content, isEnabled: true)]
        return config
    }
    private func fileInfo() throws -> stat {
        var result = stat()
        guard stat(hosts.path, &result) == 0 else { throw POSIXError(.EIO) }
        return result
    }

    func testWritingWithReadOnlyParentKeepsInodePermissionsAndTruncates() throws {
        let original = try fileInfo()
        chmod(directory.path, 0o555)
        XCTAssertThrowsError(try "replacement".write(to: hosts, atomically: true, encoding: .utf8))
        try HostsFileWriter.write(Data("short\n".utf8), to: hosts)
        XCTAssertEqual(try String(contentsOf: hosts), "short\n")
        let after = try fileInfo()
        XCTAssertEqual(after.st_ino, original.st_ino)
        XCTAssertEqual(after.st_mode, original.st_mode)
        XCTAssertEqual(after.st_uid, original.st_uid)
        XCTAssertEqual(after.st_gid, original.st_gid)
    }

    func testRepeatedAppliesNeedNoAuthorizationWithWritableFile() throws {
        var authorizationCount = 0, refreshCount = 0
        let manager = HostsManager(hostsURL: hosts, authorizeWrite: { authorizationCount += 1 }, refreshDNS: { refreshCount += 1 })
        chmod(directory.path, 0o555)
        for content in ["8.8.8.8 a.test", "127.0.0.1 b.test", "::1 c.test"] {
            let config = config(content)
            XCTAssertTrue(manager.apply(config: config), manager.lastError ?? "")
            XCTAssertEqual(try String(contentsOf: hosts), HostsManager.generateMergedContent(config: config))
            XCTAssertTrue(manager.isConfigApplied(config))
        }
        XCTAssertEqual(authorizationCount, 0)
        XCTAssertEqual(refreshCount, 3)
    }

    func testAuthorizationIsRequestedOnlyOnce() throws {
        chmod(hosts.path, 0o444)
        var authorizationCount = 0
        let manager = HostsManager(hostsURL: hosts, authorizeWrite: {
            authorizationCount += 1
            chmod(self.hosts.path, 0o644)
        }, refreshDNS: {})
        XCTAssertTrue(manager.apply(config: config()))
        XCTAssertTrue(manager.apply(config: config("127.0.0.1 next.test")))
        XCTAssertEqual(authorizationCount, 1)
    }

    func testUnchangedApplyDoesNotRewriteOrAuthorizeReadOnlyFile() throws {
        let proposed = config()
        try HostsManager.generateMergedContent(config: proposed).write(to: hosts, atomically: false, encoding: .utf8)
        chmod(hosts.path, 0o444)
        let before = try fileInfo()
        let manager = HostsManager(hostsURL: hosts, authorizeWrite: { XCTFail("No-op must not authorize") }, refreshDNS: {}, writeContent: { _, _ in XCTFail("No-op must not write") })
        XCTAssertTrue(manager.apply(config: proposed))
        XCTAssertNil(manager.lastError)
        let after = try fileInfo()
        XCTAssertEqual(before.st_mtimespec.tv_sec, after.st_mtimespec.tv_sec)
        XCTAssertEqual(before.st_mtimespec.tv_nsec, after.st_mtimespec.tv_nsec)
    }

    func testReadbackMismatchIsFailure() throws {
        let manager = HostsManager(hostsURL: hosts, authorizeWrite: { XCTFail() }, refreshDNS: { XCTFail("Must not refresh on a failed write") }, writeContent: { _, url in
            try Data("incorrect\n".utf8).write(to: url)
        })
        XCTAssertFalse(manager.apply(config: config()))
        XCTAssertNotNil(manager.lastError)
        XCTAssertNil(manager.lastApplyMessage)
        XCTAssertFalse(manager.isConfigApplied(config()))
    }

    func testFailedToggleDeleteAndApplyKeepSavedConfiguration() throws {
        let store = HostsStore(fileURL: directory.appendingPathComponent("config.json"))
        store.config = config()
        store.save()
        let original = store.config.profiles
        let originalFile = try Data(contentsOf: hosts)
        chmod(hosts.path, 0o444)
        let manager = HostsManager(hostsURL: hosts, authorizeWrite: { throw POSIXError(.EACCES) }, refreshDNS: {})
        XCTAssertFalse(store.toggleProfile(id: original[0].id, manager: manager))
        XCTAssertEqual(store.config.profiles, original)
        XCTAssertFalse(store.deleteProfile(id: original[0].id, manager: manager))
        XCTAssertEqual(store.config.profiles, original)
        var edited = original[0]
        edited.content = "1.2.3.4 changed.test"
        XCTAssertFalse(store.applyProfile(edited, manager: manager))
        XCTAssertEqual(store.config.profiles, original)
        XCTAssertEqual(try Data(contentsOf: hosts), originalFile)
        let reloaded = HostsStore(fileURL: directory.appendingPathComponent("config.json"))
        XCTAssertEqual(reloaded.config.profiles, original)
    }

    func testApplyingInactiveProfileEnablesItAndRespectsExclusiveGroup() throws {
        let store = HostsStore(fileURL: directory.appendingPathComponent("config.json"))
        store.config = HostsConfig.default
        let group = store.config.groups[0]
        let development = try XCTUnwrap(store.config.profiles.first(where: { $0.groupId == group.id && !$0.isEnabled }))
        let manager = HostsManager(hostsURL: hosts, authorizeWrite: { XCTFail() }, refreshDNS: {})
        XCTAssertTrue(store.applyProfile(development, manager: manager))
        XCTAssertTrue(store.config.profiles.first(where: { $0.id == development.id })!.isEnabled)
        XCTAssertEqual(store.config.profiles.filter { $0.groupId == group.id && $0.isEnabled }.count, 1)
        XCTAssertTrue(try String(contentsOf: hosts).contains("dev.example.com"))
        XCTAssertFalse(try String(contentsOf: hosts).contains("api-test.example.com"))
    }

    func testDeletingInactiveProfileDoesNotWriteSystemFile() {
        let store = HostsStore(fileURL: directory.appendingPathComponent("config.json"))
        let profile = store.addProfile(title: "Inactive")
        let manager = HostsManager(hostsURL: hosts, authorizeWrite: { XCTFail() }, refreshDNS: { XCTFail() }, writeContent: { _, _ in XCTFail() })
        XCTAssertTrue(store.deleteProfile(id: profile.id, manager: manager))
    }

    func testMissingSystemFileIsNotReplacedByGeneratedContent() throws {
        let manager = HostsManager(hostsURL: directory.appendingPathComponent("missing"), authorizeWrite: { XCTFail() }, refreshDNS: {})
        XCTAssertFalse(manager.apply(config: config()))
        XCTAssertNil(manager.systemContent)
        XCTAssertNotNil(manager.lastError)
    }

    func testAuthorizationCommandIsScopedAndEscaped() {
        let command = HostsManager.authorizationCommand(user: "test'name")
        XCTAssertEqual(command, "/bin/chmod +a 'user:test'\\''name allow write' /etc/hosts")
        XCTAssertFalse(command.contains("666"))
        XCTAssertFalse(command.contains("sudoers"))
    }

    func testResolutionComparesEquivalentIPFormats() {
        XCTAssertTrue(HostsResolution(hostname: "test", expected: "::1", actual: ["0:0:0:0:0:0:0:1"]).matches)
        XCTAssertTrue(HostsResolution(hostname: "test", expected: "8.8.8.8", actual: ["::ffff:8.8.8.8"]).matches)
        XCTAssertFalse(HostsResolution(hostname: "test", expected: "::1", actual: ["::2"]).matches)
    }

    func testProxyIPv6AlongsideExpectedIPv4IsOnlyPartialMatch() {
        let result = HostsResolution(hostname: "test", expected: "8.8.8.8", actual: ["8.8.8.8", "::ffff:198.18.0.30"])
        XCTAssertFalse(result.matches)
        XCTAssertTrue(result.partiallyMatches)
    }

    func testResolutionDistinguishesProxyOverrideFromFileSuccess() {
        let content = "# Header\n127.0.0.1 localhost\n255.255.255.255 broadcasthost\n8.8.8.8 test.example.com # test\n"
        let mismatch = HostsResolution.check(content: content, resolve: { host in
            XCTAssertEqual(host, "test.example.com")
            return ["198.18.0.30"]
        })
        XCTAssertEqual(mismatch?.hostname, "test.example.com")
        XCTAssertFalse(mismatch?.matches ?? true)
        XCTAssertTrue(HostsResolution.check(content: content, resolve: { _ in ["8.8.8.8"] })!.matches)
        XCTAssertFalse(HostsResolution.check(content: content, resolve: { _ in [] })!.matches)
        XCTAssertNil(HostsResolution.check(content: "# comment\ninvalid text\n127.0.0.1 localhost", resolve: { _ in XCTFail(); return [] }))
    }
}
