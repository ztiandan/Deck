import Foundation
import Combine

public class HostsStore: ObservableObject {
    public static let shared = HostsStore()

    @Published public var config: HostsConfig = .default

    private let fileURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDir = appSupport.appendingPathComponent("Deck", isDirectory: true)
        try? FileManager.default.createDirectory(at: appDir, withIntermediateDirectories: true)
        let targetURL = appDir.appendingPathComponent("hosts_config.json")

        // 迁移旧版配置（如有）
        if !FileManager.default.fileExists(atPath: targetURL.path) {
            let oldHyperKit = appSupport.appendingPathComponent("HyperKit/hosts_config.json")
            if FileManager.default.fileExists(atPath: oldHyperKit.path) {
                try? FileManager.default.copyItem(at: oldHyperKit, to: targetURL)
            }
        }

        self.fileURL = targetURL
        load()
    }

    public func load() {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoded = try JSONDecoder().decode(HostsConfig.self, from: data)
                self.config = decoded
                return
            } catch {
                print("Failed to load hosts config: \(error), using default")
            }
        }

        // 首次使用尝试读取系统现存的 /etc/hosts
        var initialConfig = HostsConfig.default
        if let currentEtcHosts = try? String(contentsOfFile: "/etc/hosts", encoding: .utf8), !currentEtcHosts.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let idx = initialConfig.profiles.firstIndex(where: { $0.title == "Default" }) {
                initialConfig.profiles[idx].content = currentEtcHosts
            }
        }
        self.config = initialConfig
        save()
    }

    public func save() {
        do {
            let data = try JSONEncoder().encode(config)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            print("Failed to save hosts config: \(error)")
        }
    }

    /// 切换某个方案的开关状态
    public func toggleProfile(id: UUID, applyToSystem: Bool = true) {
        guard let index = config.profiles.firstIndex(where: { $0.id == id }) else { return }
        let currentTarget = config.profiles[index]
        let newEnabled = !currentTarget.isEnabled

        if newEnabled, let groupId = currentTarget.groupId {
            let group = config.groups.first(where: { $0.id == groupId })
            if group?.isExclusive == true || config.exclusiveInGroup {
                // 组内互斥：同组其他设为 false
                for i in 0..<config.profiles.count {
                    if config.profiles[i].groupId == groupId && config.profiles[i].id != id {
                        config.profiles[i].isEnabled = false
                    }
                }
            }
        }

        config.profiles[index].isEnabled = newEnabled
        save()
        if applyToSystem {
            _ = HostsManager.shared.applyHostsToSystem()
        }
    }

    /// 添加新方案
    public func addProfile(title: String, content: String = "", groupId: UUID? = nil) -> HostsProfile {
        let profile = HostsProfile(
            title: title,
            content: content,
            isEnabled: false,
            groupId: groupId,
            order: config.profiles.count
        )
        config.profiles.append(profile)
        save()
        return profile
    }

    /// 删除方案
    public func deleteProfile(id: UUID, applyToSystem: Bool = true) {
        config.profiles.removeAll { $0.id == id }
        save()
        if applyToSystem {
            _ = HostsManager.shared.applyHostsToSystem()
        }
    }

    /// 更新方案
    public func updateProfile(_ profile: HostsProfile) {
        if let idx = config.profiles.firstIndex(where: { $0.id == profile.id }) {
            config.profiles[idx] = profile
            save()
        }
    }

    /// 添加分组
    public func addGroup(title: String, isExclusive: Bool = true) -> HostsGroup {
        let group = HostsGroup(title: title, isExclusive: isExclusive)
        config.groups.append(group)
        save()
        return group
    }

    /// 删除分组
    public func deleteGroup(id: UUID) {
        config.groups.removeAll { $0.id == id }
        // 将属于该分组的 profiles 移到顶层
        for i in 0..<config.profiles.count {
            if config.profiles[i].groupId == id {
                config.profiles[i].groupId = nil
            }
        }
        save()
    }
}
