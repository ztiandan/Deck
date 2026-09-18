import Foundation
import Combine

public class HostsStore: ObservableObject {
    public static let shared = HostsStore()

    @Published public var config: HostsConfig = .default

    @Published public private(set) var drafts: [UUID: String] = [:]
    private var draftSave: DispatchWorkItem?
    private let fileURL: URL
    private var draftsURL: URL { fileURL.appendingPathExtension("drafts") }

    public func editingContent(for profile: HostsProfile) -> String { drafts[profile.id] ?? profile.content }

    public func updateDraft(id: UUID, content: String) {
        guard let saved = config.profiles.first(where: { $0.id == id }) else { return }
        if content == saved.content { drafts.removeValue(forKey: id) }
        else { drafts[id] = content }
        draftSave?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.saveDrafts() }
        draftSave = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: work)
    }

    public func saveDrafts() {
        draftSave?.cancel()
        do { try ConfigurationFile.write(drafts, to: draftsURL) }
        catch { ConfigurationIssue.shared.report(error, url: draftsURL) }
    }

    private func loadDrafts() {
        guard FileManager.default.fileExists(atPath: draftsURL.path) else { return }
        do { drafts = try JSONDecoder().decode([UUID: String].self, from: Data(contentsOf: draftsURL)) }
        catch { ConfigurationIssue.shared.report(error, url: draftsURL) }
    }

    init(fileURL: URL? = nil) {
        if let fileURL {
            self.fileURL = fileURL
            load()
            loadDrafts()
            return
        }
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
        loadDrafts()
    }

    public func load() {
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                let decoded = try JSONDecoder().decode(HostsConfig.self, from: data)
                self.config = decoded
                return
            } catch {
                ConfigurationIssue.shared.report(error, url: fileURL)
                return
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

    @discardableResult
    public func save() -> Bool {
        do {
            try ConfigurationFile.write(config, to: fileURL)
            return true
        } catch {
            ConfigurationIssue.shared.report(error, url: fileURL)
            return false
        }
    }

    /// Commit the selection only after the system file has been verified.
    @discardableResult
    public func toggleProfile(id: UUID, applyToSystem: Bool = true, manager: HostsManager = .shared) -> Bool {
        guard let profile = config.profiles.first(where: { $0.id == id }) else { return false }
        var proposed = config
        Self.setEnabled(!profile.isEnabled, id: id, in: &proposed)
        if applyToSystem && !manager.apply(config: proposed) { return false }
        config = proposed
        return save()
    }

    @discardableResult
    public func applyProfile(_ profile: HostsProfile, manager: HostsManager = .shared) -> Bool {
        guard let index = config.profiles.firstIndex(where: { $0.id == profile.id }) else { return false }
        var proposed = config
        proposed.profiles[index] = profile
        // Apply means enable this profile, including group exclusivity.
        Self.setEnabled(true, id: profile.id, in: &proposed)
        guard manager.apply(config: proposed) else { return false }
        config = proposed
        guard save() else { return false }
        drafts.removeValue(forKey: profile.id)
        saveDrafts()
        return true
    }

    private static func setEnabled(_ enabled: Bool, id: UUID, in config: inout HostsConfig) {
        guard let index = config.profiles.firstIndex(where: { $0.id == id }) else { return }
        if enabled, config.exclusiveInGroup, let groupID = config.profiles[index].groupId,
           config.groups.first(where: { $0.id == groupID })?.isExclusive == true {
            for i in config.profiles.indices where config.profiles[i].groupId == groupID {
                config.profiles[i].isEnabled = false
            }
        }
        config.profiles[index].isEnabled = enabled
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

    /// Do not remove a profile from the UI if updating hosts failed.
    @discardableResult
    public func deleteProfile(id: UUID, applyToSystem: Bool = true, manager: HostsManager = .shared) -> Bool {
        guard let profile = config.profiles.first(where: { $0.id == id }) else { return false }
        var proposed = config
        proposed.profiles.removeAll { $0.id == id }
        if applyToSystem && profile.isEnabled && !manager.apply(config: proposed) { return false }
        config = proposed
        guard save() else { return false }
        drafts.removeValue(forKey: id)
        saveDrafts()
        return true
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
    public func toggleGroupExpanded(id: UUID) {
        guard let index = config.groups.firstIndex(where: { $0.id == id }) else { return }
        config.groups[index].isExpanded.toggle()
        save()
    }

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
