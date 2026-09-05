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

    func checkStatus() { status = readStatus() }

    func toggle() {
        errorMessage = nil
        checkStatus()
        do {
            switch status {
            case .enabled: try unregister()
            case .requiresApproval: openSettings()
            case .notRegistered: try register()
            case .notFound:
                errorMessage = "Install Cut & Move in Applications before enabling Launch at Login."
            @unknown default:
                errorMessage = "Unknown login-item status. Check System Settings > General > Login Items."
            }
        } catch {
            errorMessage = "Launch at Login failed: \(error.localizedDescription)"
        }
        checkStatus()
    }
}
