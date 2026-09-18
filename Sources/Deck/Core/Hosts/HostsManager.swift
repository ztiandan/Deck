import Foundation
import AppKit

public class HostsManager: ObservableObject {
    public static let shared = HostsManager()
    @Published public private(set) var systemContent: String?
    @Published public var lastError: String?
    @Published public private(set) var lastApplyMessage: String?

    private let hostsURL: URL
    private let authorizeWrite: () throws -> Void
    private let refreshDNS: () -> Void
    private let writeContent: (Data, URL) throws -> Void

    init(hostsURL: URL = URL(fileURLWithPath: "/etc/hosts"),
         authorizeWrite: (() throws -> Void)? = nil,
         refreshDNS: (() -> Void)? = nil,
         writeContent: @escaping (Data, URL) throws -> Void = HostsFileWriter.write) {
        self.hostsURL = hostsURL
        self.writeContent = writeContent
        self.authorizeWrite = authorizeWrite ?? Self.authorizeCurrentUser
        self.refreshDNS = refreshDNS ?? Self.refreshSystemDNS
        self.systemContent = try? String(contentsOf: hostsURL, encoding: .utf8)
    }

    public func generateMergedContent() -> String { Self.generateMergedContent(config: HostsStore.shared.config) }

    static func generateMergedContent(config: HostsConfig) -> String {
        let enabled = config.profiles.filter(\.isEnabled)
        if enabled.isEmpty { return "# No active hosts profiles\n" }
        return enabled.compactMap { profile -> String? in
            let clean = profile.content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { return nil }
            // A multi-line title must remain a comment, never a hosts entry.
            let title = profile.title.components(separatedBy: .newlines).joined(separator: " ")
            return "# ----------------------------\n# \(title)\n\(clean)\n\n"
        }.joined()
    }

    public func refreshSystemContent() {
        systemContent = try? String(contentsOf: hostsURL, encoding: .utf8)
    }

    public func isConfigApplied(_ config: HostsConfig) -> Bool {
        systemContent == Self.generateMergedContent(config: config)
    }

    public func isPasswordlessEnabled() -> Bool {
        FileManager.default.isWritableFile(atPath: hostsURL.path)
    }

    @discardableResult
    public func enablePasswordlessMode() -> Bool {
        lastError = nil
        do {
            if !isPasswordlessEnabled() { try authorizeWrite() }
            guard isPasswordlessEnabled() else { throw failure(loc(.hostsPermissionFailed)) }
            return true
        } catch {
            lastError = error.localizedDescription
            return false
        }
    }

    @discardableResult
    public func applyHostsToSystem() -> Bool { apply(config: HostsStore.shared.config) }

    @discardableResult
    func apply(config: HostsConfig) -> Bool {
        lastError = nil
        lastApplyMessage = nil
        let content = Self.generateMergedContent(config: config)
        do {
            // No-op applies should never request privileges or rewrite the file.
            let actual = try String(contentsOf: hostsURL, encoding: .utf8)
            if actual != content {
                if !isPasswordlessEnabled() {
                    guard enablePasswordlessMode() else { return false }
                }
                try writeContent(Data(content.utf8), hostsURL)
            }
            let verified = try String(contentsOf: hostsURL, encoding: .utf8)
            guard verified == content else { throw failure(loc(.hostsVerificationFailed)) }
            systemContent = verified
            lastApplyMessage = loc(actual == content ? .hostsAlreadyApplied : .hostsApplySuccess)
            // DNS is separate from file verification and never prompts for a password.
            refreshDNS()
            return true
        } catch {
            refreshSystemContent()
            lastError = error.localizedDescription
            return false
        }
    }

    static func authorizationCommand(user: String) -> String {
        // Limit the grant to this account and this file; do not make hosts world-writable.
        let acl = "user:\(user) allow write"
        return "/bin/chmod +a \(shellQuote(acl)) /etc/hosts"
    }

    static func shellQuote(_ text: String) -> String {
        "'" + text.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }

    private static func authorizeCurrentUser() throws {
        let command = authorizationCommand(user: NSUserName())
        func quoted(_ value: String) -> String {
            "\"" + value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"") + "\""
        }
        let source = "do shell script \(quoted(command)) with administrator privileges with prompt \(quoted(loc(.hostsAuthorizationPrompt)))"
        var error: NSDictionary?
        guard let script = NSAppleScript(source: source) else {
            throw NSError(domain: "Deck.Hosts", code: 1, userInfo: [NSLocalizedDescriptionKey: loc(.hostsPermissionFailed)])
        }
        script.executeAndReturnError(&error)
        if let error {
            let code = error[NSAppleScript.errorNumber] as? Int ?? 1
            let message = code == -128 ? loc(.hostsAuthorizationCancelled) : (error[NSAppleScript.errorMessage] as? String ?? loc(.hostsPermissionFailed))
            throw NSError(domain: "Deck.Hosts", code: code, userInfo: [NSLocalizedDescriptionKey: message])
        }
    }

    private func failure(_ message: String) -> NSError {
        NSError(domain: "Deck.Hosts", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    public func flushDNS() { refreshDNS() }

    private static func refreshSystemDNS() {
        DispatchQueue.global(qos: .utility).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/dscacheutil")
            task.arguments = ["-flushcache"]
            do {
                try task.run()
                task.waitUntilExit()
            } catch { print("DNS cache refresh failed: \(error)") }
        }
    }
}
