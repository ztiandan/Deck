import Foundation
import AppKit

public class HostsManager {
    public static let shared = HostsManager()

    private let etcHostsPath = "/etc/hosts"
    private let tempHostsPath = "/tmp/deck_hosts.tmp"

    private init() {}

    /// 获取合并所有已启用 profile 后的完整 hosts 字符串
    public func generateMergedContent() -> String {
        let store = HostsStore.shared
        let enabledProfiles = store.config.profiles.filter { $0.isEnabled }

        if enabledProfiles.isEmpty {
            return "# No active hosts profiles\n"
        }

        var result = ""
        for profile in enabledProfiles {
            let clean = profile.content.trimmingCharacters(in: .whitespacesAndNewlines)
            if clean.isEmpty { continue }

            result += "# ----------------------------\n"
            result += "# \(profile.title)\n"
            result += clean + "\n\n"
        }

        return result
    }

    /// 检查 /etc/hosts 是否已被配置为免密码可写
    public func isPasswordlessEnabled() -> Bool {
        return FileManager.default.isWritableFile(atPath: etcHostsPath)
    }

    /// 一键开启免密码切换（执行一次授权 chmod 666 /etc/hosts）
    @discardableResult
    public func enablePasswordlessMode() -> Bool {
        let script = "do shell script \"chmod 666 /etc/hosts\" with administrator privileges"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if error == nil {
                print("Successfully enabled passwordless mode for /etc/hosts")
                return true
            }
        }
        print("Failed to enable passwordless mode: \(String(describing: error))")
        return false
    }

    /// 将合并后的内容应用并写回系统 /etc/hosts
    @discardableResult
    public func applyHostsToSystem() -> Bool {
        let content = generateMergedContent()

        // 1. 如果已开启免密写入权限，直接写入，耗时 < 1ms
        if isPasswordlessEnabled() {
            do {
                try content.write(toFile: etcHostsPath, atomically: true, encoding: .utf8)
                flushDNS()
                print("Directly applied hosts to /etc/hosts (passwordless)")
                return true
            } catch {
                print("Direct write failed, trying privileged write: \(error)")
            }
        }

        // 2. 特权写入：先写临时文件，再通过 AppleScript 提权覆盖
        do {
            try content.write(toFile: tempHostsPath, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write to temp file: \(error)")
            return false
        }

        let script = "do shell script \"cp '\(tempHostsPath)' '\(etcHostsPath)' && dscacheutil -flushcache && killall -HUP mDNSResponder\" with administrator privileges"
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)
            if let error = error {
                print("Privileged apply failed: \(error)")
                return false
            } else {
                print("Privileged hosts update succeeded")
                return true
            }
        }

        return false
    }

    /// 刷新 macOS 系统 DNS 缓存
    public func flushDNS() {
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
            task.arguments = ["-flushcache"]
            try? task.run()
            task.waitUntilExit()

            let killTask = Process()
            killTask.executableURL = URL(fileURLWithPath: "/usr/bin/killall")
            killTask.arguments = ["-HUP", "mDNSResponder"]
            try? killTask.run()
        }
    }
}
