import Combine
import ServiceManagement

class LaunchManager: ObservableObject {
    static let shared = LaunchManager()
    @Published private(set) var status: SMAppService.Status = .notRegistered
    @Published private(set) var errorMessage: String?
    var isEnabled: Bool { status == .enabled }
    var requiresApproval: Bool { status == .requiresApproval }

    private let readStatus: () -> SMAppService.Status
    private let register: () throws -> Void
    private let unregister: () throws -> Void
    private let openSettings: () -> Void

    init(readStatus: @escaping () -> SMAppService.Status = { SMAppService.mainApp.status },
         register: @escaping () throws -> Void = { try SMAppService.mainApp.register() },
         unregister: @escaping () throws -> Void = { try SMAppService.mainApp.unregister() },
         openSettings: @escaping () -> Void = { SMAppService.openSystemSettingsLoginItems() }) {
        self.readStatus = readStatus
        self.register = register
        self.unregister = unregister
        self.openSettings = openSettings
        checkStatus()
    }

    func checkStatus() {
        let updated = readStatus()
        if updated != status && (updated == .enabled || updated == .requiresApproval) {
            errorMessage = nil
        }
        status = updated
    }

    func toggle() {
        errorMessage = nil
        checkStatus()
        do {
            switch status {
            case .enabled: try unregister()
            case .requiresApproval: openSettings()
            case .notRegistered, .notFound:
                // A missing service is not evidence of an incorrect installation path.
                // Let ServiceManagement attempt registration and report its actual result.
                try register()
                checkStatus()
                if status != .enabled && status != .requiresApproval {
                    errorMessage = "macOS has not confirmed Launch at Login. Check System Settings > General > Login Items, then try again."
                }
            @unknown default:
                errorMessage = "Unknown login-item status. Check System Settings > General > Login Items."
            }
        } catch {
            let failure = error as NSError
            errorMessage = "Launch at Login failed: \(failure.localizedDescription) (\(failure.domain), \(failure.code)). Check System Settings > General > Login Items."
        }
        checkStatus()
    }
}
