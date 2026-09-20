import Foundation
import AppKit
import Combine

public class TimezoneManager: ObservableObject {
    public static let shared = TimezoneManager()

    @Published public private(set) var currentTimezone: String = "Asia/Shanghai"
    @Published public private(set) var currentFormattedTime: String = ""
    @Published public private(set) var currentFormattedDate: String = ""
    @Published public var lastError: String?
    @Published public var lastSuccessMessage: String?
    @Published public var isSwitching: Bool = false
    @Published public var isPasswordless: Bool = false

    private var timer: AnyCancellable?
    private let sudoersPath = "/private/etc/sudoers.d/deck_timezone"

    public var currentItem: TimezoneItem {
        TimezoneDatabase.find(by: currentTimezone) ?? TimezoneItem(
            identifier: currentTimezone,
            countryName: currentTimezone.components(separatedBy: "/").first ?? "System",
            cityName: currentTimezone.components(separatedBy: "/").last?.replacingOccurrences(of: "_", with: " ") ?? currentTimezone,
            flag: "🌍",
            region: .other
        )
    }

    public var currentCityName: String {
        currentItem.cityName
    }

    public var currentTimezoneShort: String {
        if let last = currentTimezone.components(separatedBy: "/").last {
            return last.replacingOccurrences(of: "_", with: " ")
        }
        return currentTimezone
    }

    init() {
        refreshCurrentTimezone()
        checkPasswordlessStatus()
        startClockTimer()

        // 监听系统时区变动通知
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.NSSystemTimeZoneDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshCurrentTimezone()
        }

        // 监听 App 激活事件
        NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshCurrentTimezone()
            self?.checkPasswordlessStatus()
        }
    }

    private func startClockTimer() {
        updateClockDisplay()
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateClockDisplay()
            }
    }

    private func updateClockDisplay() {
        let now = Date()
        let formatter = DateFormatter()
        formatter.timeZone = TimeZone(identifier: currentTimezone) ?? TimeZone.current

        formatter.dateFormat = "HH:mm:ss"
        currentFormattedTime = formatter.string(from: now)

        formatter.dateFormat = LocalizationManager.shared.currentLanguage == .chinese ? "yyyy年MM月dd日 EEEE" : "EEEE, MMM d, yyyy"
        formatter.locale = Locale(identifier: LocalizationManager.shared.currentLanguage.rawValue)
        currentFormattedDate = formatter.string(from: now)
    }

    /// 读取系统当前的实际生效时区
    public func refreshCurrentTimezone() {
        NSTimeZone.resetSystemTimeZone()

        // 首选通过 /etc/localtime 软链接路径精准获取
        let localtimeURL = URL(fileURLWithPath: "/etc/localtime")
        let resolved = localtimeURL.resolvingSymlinksInPath().path

        var matchedTZ: String?
        let prefixes = [
            "/private/var/db/timezone/zoneinfo/",
            "/var/db/timezone/zoneinfo/",
            "/usr/share/zoneinfo/",
            "/private/usr/share/zoneinfo/"
        ]

        for prefix in prefixes {
            if resolved.hasPrefix(prefix) {
                let suffix = String(resolved.dropFirst(prefix.count))
                if !suffix.isEmpty {
                    matchedTZ = suffix
                    break
                }
            }
        }

        let detected = matchedTZ ?? TimeZone.current.identifier
        if currentTimezone != detected {
            currentTimezone = detected
            updateClockDisplay()
        }
    }

    /// 检查是否已开启免密权限
    public func checkPasswordlessStatus() {
        if FileManager.default.fileExists(atPath: sudoersPath) {
            isPasswordless = true
            return
        }

        // 测试 sudo -n 是否可用
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            process.arguments = ["-n", "/usr/sbin/systemsetup", "-gettimezone"]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
                let available = (process.terminationStatus == 0)
                DispatchQueue.main.async {
                    self?.isPasswordless = available
                }
            } catch {
                DispatchQueue.main.async {
                    self?.isPasswordless = false
                }
            }
        }
    }

    /// 启用免密模式（写入 /etc/sudoers.d/deck_timezone）
    @discardableResult
    public func enablePasswordlessMode() -> Bool {
        lastError = nil
        let username = NSUserName()
        let sudoersContent = "\(username) ALL=(ALL) NOPASSWD: /usr/sbin/systemsetup -settimezone *"
        let cmd = "echo \(HostsManager.shellQuote(sudoersContent)) > \(sudoersPath) && chmod 0440 \(sudoersPath)"

        do {
            try executeAppleScriptCommand(cmd, prompt: loc(.tzAuthorizationPrompt))
            checkPasswordlessStatus()
            lastSuccessMessage = loc(.tzPasswordlessSuccess)
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    /// 切换系统时区
    @discardableResult
    public func setTimezone(_ identifier: String) -> Bool {
        guard !identifier.isEmpty else { return false }
        if identifier == currentTimezone {
            return true
        }

        isSwitching = true
        lastError = nil
        lastSuccessMessage = nil

        defer {
            isSwitching = false
        }

        // 1. 如果支持免密 sudo，直接调用 sudo -n
        if isPasswordless {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
            process.arguments = ["-n", "/usr/sbin/systemsetup", "-settimezone", identifier]
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            do {
                try process.run()
                process.waitUntilExit()
                if process.terminationStatus == 0 {
                    finalizeTimezoneChange(to: identifier)
                    return true
                }
            } catch {
                // 回退到管理员权限弹窗
            }
        }

        // 2. 通过 AppleScript 调起原生管理员提权执行
        let shellCommand = "/usr/sbin/systemsetup -settimezone \(HostsManager.shellQuote(identifier))"
        do {
            try executeAppleScriptCommand(shellCommand, prompt: loc(.tzAuthorizationPrompt))
            finalizeTimezoneChange(to: identifier)
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    private func finalizeTimezoneChange(to identifier: String) {
        currentTimezone = identifier
        NSTimeZone.resetSystemTimeZone()
        NotificationCenter.default.post(name: NSNotification.Name.NSSystemTimeZoneDidChange, object: nil)
        refreshCurrentTimezone()
        updateClockDisplay()
        lastSuccessMessage = loc(.tzSwitchSuccess)

        // 刷新菜单栏
        DispatchQueue.main.async {
            MenuBarManager.shared.rebuildMenu()
        }
    }

    private func executeAppleScriptCommand(_ command: String, prompt: String) throws {
        func quoted(_ value: String) -> String {
            "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
        }
        let source = "do shell script \(quoted(command)) with administrator privileges with prompt \(quoted(prompt))"
        var errorDict: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw NSError(domain: "Deck.Timezone", code: 1, userInfo: [NSLocalizedDescriptionKey: loc(.tzSwitchFailed)])
        }

        script.executeAndReturnError(&errorDict)
        if let errorDict {
            let code = errorDict[NSAppleScript.errorNumber] as? Int ?? 1
            let message = code == -128
                ? loc(.hostsAuthorizationCancelled)
                : (errorDict[NSAppleScript.errorMessage] as? String ?? loc(.tzSwitchFailed))
            throw NSError(domain: "Deck.Timezone", code: code, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }
}
