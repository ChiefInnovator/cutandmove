import Cocoa
import FinderSync

final class FinderSync: FIFinderSync {
    private let bridge = try? FinderBridge()
    private var status = FinderStatus()
    private var timer: Timer?
    private var failure: String?
    private var actions = FinderMenuActions()

    override init() {
        super.init()
        let image = NSImage(systemSymbolName: "scissors.circle.fill", accessibilityDescription: "Ready to move")!
        FIFinderSyncController.default().setBadgeImage(image, label: "Cut & Move: ready to move", forBadgeIdentifier: "cut")
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in self?.refresh() }
    }

    private func refresh() {
        // Finder Sync scopes UI recursively. Cover the filesystem and every
        // mounted volume automatically, including drives mounted after launch.
        // Registration does not scan files or grant additional file access.
        let directories = Set([URL(fileURLWithPath: "/", isDirectory: true)] +
            (FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: []) ?? []))
        let controller = FIFinderSyncController.default()
        if controller.directoryURLs != directories { controller.directoryURLs = directories }
        guard let bridge else { failure = "Open Cut & Move to set up Finder integration."; return }
        do {
            var latest = try bridge.status()
            if let cut = latest.cut, cut.clipboard != NSPasteboard.general.changeCount { latest.cut = nil }
            if latest != status {
                let affected = Set((status.cut?.urls ?? []) + (latest.cut?.urls ?? []))
                status = latest
                for url in affected { requestBadgeIdentifier(for: url) }
            }
            failure = nil
        } catch { failure = "Finder integration is unavailable. Open Cut & Move to retry." }
    }

    override func requestBadgeIdentifier(for url: URL) {
        let normalized = url.deletingLastPathComponent().resolvingSymlinksInPath().appendingPathComponent(url.lastPathComponent)
        let cut = status.cut?.urls.contains(normalized) == true
        FIFinderSyncController.default().setBadgeIdentifier(cut ? "cut" : "", for: url)
    }

    override var toolbarItemName: String { "Cut & Move" }
    override var toolbarItemToolTip: String { "Cut & Move — cut selected items, move here, or cancel" }
    override var toolbarItemImage: NSImage { NSImage(systemSymbolName: "scissors", accessibilityDescription: "Cut & Move")! }

    override func menu(for menuKind: FIMenuKind) -> NSMenu? {
        refresh()
        let controller = FIFinderSyncController.default()
        let selected = controller.selectedItemURLs() ?? []
        let target = controller.targetedURL()
        let menu = NSMenu(title: "Cut & Move")
        menu.autoenablesItems = false
        let cut = NSMenuItem(title: "Cut with Cut & Move", action: #selector(send(_:)), keyEquivalent: "")
        cut.target = self
        cut.tag = actions.register(FinderRequest(action: .cut, urls: selected))
        cut.isEnabled = !selected.isEmpty && !status.busy && failure == nil
        menu.addItem(cut)

        // Background and toolbar targets refer to the current folder. An item
        // context can offer Move Here only when its target is itself a folder.
        let directory = target.flatMap { try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory } == true
        let destination = (menuKind == .contextualMenuForContainer || menuKind == .toolbarItemMenu || directory) ? target : nil
        let move = NSMenuItem(title: "Move \(status.cut?.urls.count ?? 0) Item(s) Here", action: #selector(send(_:)), keyEquivalent: "")
        move.target = self
        move.tag = actions.register(FinderRequest(action: .move, urls: destination.map { [$0] } ?? [], cutID: status.cut?.id))
        move.isEnabled = destination != nil && status.cut != nil && !status.busy && failure == nil
        menu.addItem(move)
        let cancel = NSMenuItem(title: "Cancel Cut", action: #selector(send(_:)), keyEquivalent: "")
        cancel.target = self
        cancel.tag = actions.register(FinderRequest(action: .cancel, cutID: status.cut?.id))
        cancel.isEnabled = status.cut != nil && !status.busy
        menu.addItem(cancel)
        if let message = failure ?? status.message {
            let info = NSMenuItem(title: message, action: nil, keyEquivalent: "")
            info.isEnabled = false
            menu.addItem(info)
        }
        menu.addItem(.separator())
        let open = NSMenuItem(title: "Open Cut & Move", action: #selector(openApp), keyEquivalent: "")
        open.target = self
        menu.addItem(open)
        return menu
    }

    @objc private func send(_ sender: NSMenuItem) {
        guard var request = actions.request(for: sender.tag), let bridge else { NSSound.beep(); return }
        request.created = Date()
        do {
            try bridge.send(request)
            openApp()
        } catch { failure = "Could not send the Finder action. Please try again."; NSSound.beep() }
    }

    @objc private func openApp() {
        // The containing signed app, never a handler chosen by an external URL.
        let app = Bundle.main.bundleURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        NSWorkspace.shared.openApplication(at: app, configuration: configuration) { _, error in
            if error != nil { DispatchQueue.main.async { self.failure = "Open Cut & Move from Applications, then retry." } }
        }
    }
}
