import Cocoa
import Combine
import FinderSync
import Darwin

@MainActor
final class FinderIntegration: ObservableObject {
    static let shared = FinderIntegration()
    @Published private(set) var status = FinderStatus()
    @Published private(set) var extensionEnabled = false
    @Published private(set) var folders: [URL] = []
    private var bridge: FinderBridge?
    private var timer: Timer?
    private var items: [CutFile] = []
    private var keyboardClipboard: Int?
    private var copyDeadline = Date.distantPast
    private var applying = false
    private var lock: Int32 = -1

    func start() {
        guard timer == nil else { return }
        do {
            let store = try FinderBridge()
            let descriptor = open(store.directory.appendingPathComponent("host.lock").path, O_CREAT | O_RDWR, 0o600)
            guard descriptor >= 0 else { throw MoveFailure("Could not open Finder integration state.") }
            guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
                close(descriptor)
                throw MoveFailure("Another copy of Cut & Move is already handling Finder actions.")
            }
            lock = descriptor
            bridge = store
            folders = try store.folders()
            if !FileManager.default.fileExists(atPath: store.directory.appendingPathComponent("folders.json").path) {
                folders = [FileManager.default.homeDirectoryForCurrentUser, URL(fileURLWithPath: "/Volumes", isDirectory: true)]
                try store.setFolders(folders)
            }
            // Never resume an old destructive request or stale cut after a restart.
            status = FinderStatus()
            try store.publish(status)
            GlobalKeyboardHandler.shared.cutDidChange = { [weak self] count in
                guard let self, !self.applying, !self.status.busy else { return }
                self.keyboardClipboard = count
                self.copyDeadline = Date().addingTimeInterval(1)
                if count == nil { self.clear() }
            }
            timer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated { self?.tick() }
            }
            tick()
        } catch { status.message = error.localizedDescription }
    }

    func configureExtension() { FIFinderSyncController.showExtensionManagementInterface() }

    func stop() {
        timer?.invalidate()
        timer = nil
        GlobalKeyboardHandler.shared.cutDidChange = nil
        if lock >= 0 {
            status = FinderStatus()
            publish()
            close(lock)
            lock = -1
        }
    }

    func addFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Show Finder Actions Here"
        guard panel.runModal() == .OK else { return }
        do {
            let updated = Array(Set(folders + panel.urls)).sorted { $0.path < $1.path }
            try bridge?.setFolders(updated)
            folders = updated
        } catch { report(error.localizedDescription) }
    }

    func removeFolder(_ folder: URL) {
        do {
            let updated = folders.filter { $0 != folder }
            try bridge?.setFolders(updated)
            folders = updated
        } catch { report(error.localizedDescription) }
    }

    func cancel() {
        guard !status.busy else { return }
        applying = true
        GlobalKeyboardHandler.shared.cancelCut()
        applying = false
        clear()
    }

    private func clear() {
        keyboardClipboard = nil
        items = []
        status.cut = nil
        publish()
    }

    private func publish() {
        status.updated = Date()
        do { try bridge?.publish(status) }
        catch { status.message = "Finder integration could not save its state: \(error.localizedDescription)" }
    }

    private func report(_ message: String) {
        status.message = message
        publish()
        NSSound.beep()
    }

    private func tick() {
        extensionEnabled = FIFinderSyncController.isExtensionEnabled
        guard let bridge, !status.busy else { return }
        let board = NSPasteboard.general
        if let cut = status.cut, board.changeCount != cut.clipboard {
            if let expected = keyboardClipboard, expected != cut.clipboard {
                // A new Cmd+X replaces the old selection. Do not cancel the new
                // pending Copy while waiting for Finder to update the clipboard.
                status.cut = nil
                items = []
                publish()
            } else { cancel() }
        }
        if let expected = keyboardClipboard, status.cut?.clipboard != expected {
            if board.changeCount == expected,
               let urls = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty {
                do {
                    items = try FileMoveService.capture(urls)
                    status.cut = FinderCut(id: UUID(), urls: items.map(\.url), clipboard: expected)
                    status.message = nil
                    publish()
                } catch { cancel(); report(error.localizedDescription) }
            } else if Date() > copyDeadline || board.changeCount > expected { cancel() }
        }
        do {
            for (file, request) in try bridge.requests() {
                // Claim before execution: a crash must not repeat a move request.
                try bridge.acknowledge(file)
                guard abs(request.created.timeIntervalSinceNow) < 30 else {
                    report("A Finder action expired. Please select the items and try again.")
                    continue
                }
                try perform(request)
                if status.busy { break }
            }
        } catch { report(error.localizedDescription) }
    }

    private func perform(_ request: FinderRequest) throws {
        let board = NSPasteboard.general
        switch request.action {
        case .cut:
            let selected = try FileMoveService.capture(request.urls)
            board.clearContents()
            guard board.writeObjects(selected.map { $0.url as NSURL }) else { throw MoveFailure("Could not place the selected files on the clipboard.") }
            items = selected
            status.cut = FinderCut(id: UUID(), urls: selected.map(\.url), clipboard: board.changeCount)
            status.message = nil
            applying = true
            if GlobalKeyboardHandler.shared.isMonitoring { GlobalKeyboardHandler.shared.armCut(clipboard: board.changeCount) }
            applying = false
            keyboardClipboard = nil
            publish()
        case .cancel:
            guard request.cutID == status.cut?.id else { return }
            cancel()
        case .move:
            guard let cut = status.cut, request.cutID == cut.id, cut.clipboard == board.changeCount,
                  request.urls.count == 1, !items.isEmpty else { throw MoveFailure("The cut selection changed. Select the files and choose Cut again.") }
            status.busy = true
            keyboardClipboard = nil
            status.message = "Moving \(items.count) item(s)…"
            GlobalKeyboardHandler.shared.fileMoveInProgress = true
            GlobalKeyboardHandler.shared.cancelCut()
            publish()
            let selected = items
            let destination = request.urls[0]
            Task {
                let result = await Task.detached { FileMoveService.move(selected, destination: destination) }.value
                self.status.busy = false
                GlobalKeyboardHandler.shared.fileMoveInProgress = false
                self.items = result.remaining
                if board.changeCount == cut.clipboard, !result.remaining.isEmpty {
                    board.clearContents()
                    board.writeObjects(result.remaining.map { $0.url as NSURL })
                    self.status.cut = FinderCut(id: UUID(), urls: result.remaining.map(\.url), clipboard: board.changeCount)
                    self.applying = true
                    if GlobalKeyboardHandler.shared.isMonitoring { GlobalKeyboardHandler.shared.armCut(clipboard: board.changeCount) }
                    self.applying = false
                } else { self.clear() }
                self.status.message = result.error.map { "Moved \(result.moved) item(s). \($0)" } ?? "Moved \(result.moved) item(s)."
                self.publish()
                if result.error != nil { NSSound.beep() }
            }
        }
    }
}
