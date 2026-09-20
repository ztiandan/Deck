import Foundation
import ServiceManagement

public class LaunchAtLoginManager: ObservableObject {
    public static let shared = LaunchAtLoginManager()

    @Published public private(set) var isEnabled: Bool = false
    @Published public var lastError: String?

    public init() {
        refresh()
    }

    public func refresh() {
        if #available(macOS 13.0, *) {
            isEnabled = (SMAppService.mainApp.status == .enabled)
        }
    }

    public func setEnabled(_ enabled: Bool) {
        lastError = nil
        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                refresh()
            } catch {
                lastError = error.localizedDescription
                refresh()
            }
        }
    }
}
