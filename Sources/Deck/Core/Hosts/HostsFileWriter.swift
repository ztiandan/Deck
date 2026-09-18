import Foundation
import Darwin

/// Update the existing inode: an ACL can allow writing hosts without granting
/// permission to replace files in /etc. Atomic URL writes require the latter.
enum HostsFileWriter {
    static func write(_ data: Data, to url: URL) throws {
        let path = url.resolvingSymlinksInPath().path
        let fd = open(path, O_RDWR | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else { throw posixError() }
        defer { close(fd) }
        guard flock(fd, LOCK_EX | LOCK_NB) == 0 else { throw posixError() }
        defer { flock(fd, LOCK_UN) }
        var info = stat()
        guard fstat(fd, &info) == 0 else { throw posixError() }
        guard (info.st_mode & S_IFMT) == S_IFREG else { throw POSIXError(.EINVAL) }
        let handle = FileHandle(fileDescriptor: fd, closeOnDealloc: false)
        let original = try handle.readToEnd() ?? Data()
        do {
            try replace(data, using: handle)
            try handle.seek(toOffset: 0)
            guard try handle.readToEnd() == data else { throw POSIXError(.EIO) }
        } catch {
            // Restore the previous contents if a partial write or verification fails.
            do { try replace(original, using: handle) }
            catch { throw NSError(domain: "Deck.Hosts", code: 2, userInfo: [NSLocalizedDescriptionKey: loc(.hostsRestoreFailed)]) }
            throw error
        }
    }

    private static func replace(_ data: Data, using handle: FileHandle) throws {
        try handle.seek(toOffset: 0)
        try handle.write(contentsOf: data)
        try handle.truncate(atOffset: UInt64(data.count))
        try handle.synchronize()
    }

    private static func posixError() -> POSIXError { POSIXError(POSIXErrorCode(rawValue: errno) ?? .EIO) }
}
