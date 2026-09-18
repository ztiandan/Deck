import Foundation

public struct HostsProfile: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var content: String
    public var isEnabled: Bool
    public var groupId: UUID?
    public var order: Int

    public init(
        id: UUID = UUID(),
        title: String,
        content: String = "",
        isEnabled: Bool = false,
        groupId: UUID? = nil,
        order: Int = 0
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.isEnabled = isEnabled
        self.groupId = groupId
        self.order = order
    }
}

public struct HostsGroup: Identifiable, Codable, Equatable {
    public var id: UUID
    public var title: String
    public var isExpanded: Bool
    public var isExclusive: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        isExpanded: Bool = true,
        isExclusive: Bool = true
    ) {
        self.id = id
        self.title = title
        self.isExpanded = isExpanded
        self.isExclusive = isExclusive
    }
}

public struct HostsConfig: Codable {
    public var startAtLogin: Bool = false
    public var previewOnHover: Bool = true
    public var exclusiveInGroup: Bool = true
    public var menuShortcut: String = "⇧⌘E"
    public var groups: [HostsGroup] = []
    public var profiles: [HostsProfile] = []

    public init() {}

    public static var `default`: HostsConfig {
        var config = HostsConfig()
        let defaultContent = """
##
# Host Database
#
# localhost is used to configure the loopback interface
# when the system is booting.  Do not change this entry.
##
127.0.0.1\tlocalhost
255.255.255.255\tbroadcasthost
::1             localhost
"""
        let defaultProfile = HostsProfile(
            title: "Default",
            content: defaultContent,
            isEnabled: true,
            order: 0
        )

        let demoGroup = HostsGroup(title: "Demo Domain", isExpanded: true, isExclusive: true)

        let devProfile = HostsProfile(
            title: "Development",
            content: "# Development environment\n127.0.0.1 dev.example.com\n127.0.0.1 api-dev.example.com",
            isEnabled: false,
            groupId: demoGroup.id,
            order: 1
        )

        let testProfile = HostsProfile(
            title: "Test",
            content: "# Test environment\n127.0.0.1 test.example.com\n127.0.0.1 api-test.example.com",
            isEnabled: false,
            groupId: demoGroup.id,
            order: 2
        )

        config.groups = [demoGroup]
        config.profiles = [defaultProfile, devProfile, testProfile]
        return config
    }
}
