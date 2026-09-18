import Foundation
import Darwin

struct HostsResolution {
    let hostname: String
    let expected: String
    let actual: [String]
    var expectedAlternatives: [String] = []
    private var expectedAddresses: [[UInt8]] {
        ([expected] + expectedAlternatives).compactMap(Self.addressBytes)
    }
    var matches: Bool {
        let expectedIPs = expectedAddresses
        return !actual.isEmpty && actual.allSatisfy { address in
            guard let bytes = Self.addressBytes(address) else { return false }
            return expectedIPs.contains(bytes)
        }
    }

    var partiallyMatches: Bool {
        guard !matches else { return false }
        return actual.contains { address in
            guard let bytes = Self.addressBytes(address) else { return false }
            return expectedAddresses.contains(bytes)
        }
    }

    private static func addressBytes(_ text: String) -> [UInt8]? {
        var ipv4 = in_addr(), ipv6 = in6_addr()
        if inet_pton(AF_INET, text, &ipv4) == 1 {
            // Compare IPv4 and IPv4-mapped IPv6 consistently.
            return Array(repeating: 0, count: 10) + [255, 255] + withUnsafeBytes(of: &ipv4) { Array($0) }
        }
        if inet_pton(AF_INET6, text, &ipv6) == 1 {
            return withUnsafeBytes(of: &ipv6) { Array($0) }
        }
        return nil
    }

    /// Check the first custom mapping, skipping system loopback entries.
    static func check(content: String, resolve: (String) -> [String] = resolveHost) -> Self? {
        let entries = content.components(separatedBy: .newlines).compactMap { line -> [String]? in
            let fields = line.split(separator: "#", maxSplits: 1, omittingEmptySubsequences: false)[0]
                .split(whereSeparator: \.isWhitespace).map(String.init)
            guard fields.count >= 2 else { return nil }
            var ipv4 = in_addr(), ipv6 = in6_addr()
            guard inet_pton(AF_INET, fields[0], &ipv4) == 1 || inet_pton(AF_INET6, fields[0], &ipv6) == 1 else { return nil }
            return fields
        }
        for fields in entries {
            if let hostname = fields.dropFirst().first(where: { !["localhost", "broadcasthost"].contains($0.lowercased()) }) {
                let alternatives = entries.filter { entry in
                    entry.dropFirst().contains { $0.caseInsensitiveCompare(hostname) == .orderedSame }
                }.map { $0[0] }.filter { $0 != fields[0] }
                return Self(hostname: hostname, expected: fields[0], actual: resolve(hostname), expectedAlternatives: alternatives)
            }
        }
        return nil
    }

    static func resolveHost(_ hostname: String) -> [String] {
        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM
        var result: UnsafeMutablePointer<addrinfo>?
        guard getaddrinfo(hostname, nil, &hints, &result) == 0, let first = result else { return [] }
        defer { freeaddrinfo(first) }
        var addresses = Set<String>()
        var next: UnsafeMutablePointer<addrinfo>? = first
        while let current = next {
            let entry = current.pointee
            var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if getnameinfo(entry.ai_addr, entry.ai_addrlen, &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 {
                addresses.insert(String(cString: buffer))
            }
            next = entry.ai_next
        }
        return addresses.sorted()
    }

    var message: String {
        String(format: loc(matches ? .hostsResolutionMatches : (partiallyMatches ? .hostsResolutionMixed : .hostsResolutionMismatch)),
               hostname, ([expected] + expectedAlternatives).joined(separator: ", "), actual.isEmpty ? loc(.hostsResolutionMissing) : actual.joined(separator: ", "))
    }
}
