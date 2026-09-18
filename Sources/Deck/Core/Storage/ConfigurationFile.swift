import Foundation
import Combine

final class ConfigurationIssue: ObservableObject {
    static let shared = ConfigurationIssue()
    @Published var message: String?
    func report(_ error: Error, url: URL) {
        message = "\(url.lastPathComponent): \(error.localizedDescription)"
    }
}

enum ConfigurationFile {
    static func write<Value: Codable>(_ value: Value, to url: URL) throws {
        let data = try JSONEncoder().encode(value)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: url.path) {
            let existing = try Data(contentsOf: url)
            if (try? JSONDecoder().decode(Value.self, from: existing)) == nil {
                // Preserve malformed/unsupported user data before any recovery save.
                let backup = url.appendingPathExtension("recovery-\(UUID().uuidString)")
                try existing.write(to: backup, options: .withoutOverwriting)
            }
        }
        try data.write(to: url, options: .atomic)
    }
}
