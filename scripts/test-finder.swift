// Opt-in live Finder regression test. Requires Accessibility and Finder Automation.
// Compile with CutAndMove/ShortcutState.swift and CutAndMove/GlobalKeyboardHandler.swift.
// Uses disposable files and temporarily puts Finder in front; do not type during the test.
import Cocoa

@main
struct FinderRegression {
    static var state = ShortcutState()
    static var focusRejected = false

    static func settle() {
        RunLoop.current.run(until: Date().addingTimeInterval(0.5))
    }

    static func finder(_ command: String) throws {
        var error: NSDictionary?
        NSAppleScript(source: "tell application \"Finder\"\n\(command)\nend tell")!
            .executeAndReturnError(&error)
        if let error { throw NSError(domain: "FinderRegression", code: 1, userInfo: error as? [String: Any]) }
        settle()
    }

    static func key(_ code: CGKeyCode) throws {
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder" else {
            throw NSError(domain: "FinderRegression", code: 2, userInfo: [NSLocalizedDescriptionKey: "Finder lost focus; test stopped."])
        }
        // Changing view styles can leave Finder's AX focus unsettled briefly.
        // Wait for a real file context before exercising the keyboard callback.
        let pid = NSWorkspace.shared.frontmostApplication!.processIdentifier
        let deadline = Date().addingTimeInterval(3)
        while !FinderFocus.isFileContext(pid: pid) && Date() < deadline { settle() }
        try require(FinderFocus.isFileContext(pid: pid), "Finder file context did not become ready.")
        for down in [true, false] {
            let event = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: down)!
            event.flags = .maskCommand
            event.post(tap: .cghidEventTap)
        }
        settle()
    }

    static func require(_ condition: Bool, _ message: String) throws {
        if !condition { throw NSError(domain: "FinderRegression", code: 3, userInfo: [NSLocalizedDescriptionKey: message]) }
    }

    static func main() {
        do { try run() }
        catch {
            fputs("FAIL: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    static func run() throws {
        let view = CommandLine.arguments.dropFirst().first ?? "list"
        try require(["list", "icon", "column", "flow"].contains(view), "View must be list, icon, column, or flow (gallery).")
        try require(AXIsProcessTrusted(), "Accessibility access is required; no settings were changed.")
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("cutandmove-regression-\(UUID().uuidString)")
        let source = root.appendingPathComponent("source")
        let destination = root.appendingPathComponent("destination")
        try fm.createDirectory(at: source, withIntermediateDirectories: true)
        try fm.createDirectory(at: destination, withIntermediateDirectories: true)
        let file = source.appendingPathComponent("probe.txt")
        let content = Data("Disposable Cut & Move regression fixture.\n".utf8)
        try content.write(to: file)
        let previousApp = NSWorkspace.shared.frontmostApplication
        let board = NSPasteboard.general
        let saved = (board.pasteboardItems ?? []).map { item in
            item.types.compactMap { type in item.data(forType: type).map { (type, $0) } }
        }
        var lastCount = board.changeCount
        defer {
            if board.changeCount == lastCount {
                board.clearContents()
                board.writeObjects(saved.map { entries in
                    let item = NSPasteboardItem()
                    for (type, data) in entries { item.setData(data, forType: type) }
                    return item
                })
            }
            try? finder("close every Finder window whose target is folder (POSIX file \"\(source.path)\")")
            try? finder("close every Finder window whose target is folder (POSIX file \"\(destination.path)\")")
            try? fm.removeItem(at: root) // Only this run's UUID-scoped fixtures.
            previousApp?.activate()
        }
        guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap,
            options: .defaultTap, eventsOfInterest: (1 << 10) | (1 << 11), callback: { _, _, event, _ in
                guard let app = NSWorkspace.shared.frontmostApplication, app.bundleIdentifier == "com.apple.finder" else {
                    FinderRegression.state.reset()
                    return Unmanaged.passUnretained(event)
                }
                let key = event.getIntegerValueField(.keyboardEventKeycode)
                let relevant = event.type == .keyDown && [7, 9].contains(key) && event.flags.contains(.maskCommand)
                let context = !relevant || FinderFocus.isFileContext(pid: app.processIdentifier)
                if relevant && !context { FinderRegression.focusRejected = true }
                let board = NSPasteboard.general
                let pass = FinderRegression.state.process(event, fileContext: context, clipboard: board.changeCount,
                    hasFiles: board.canReadObject(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]))
                return pass ? Unmanaged.passUnretained(event) : nil
            }, userInfo: nil) else {
            throw NSError(domain: "FinderRegression", code: 4, userInfo: [NSLocalizedDescriptionKey: "Could not create diagnostic keyboard tap."])
        }
        defer { CFMachPortInvalidate(tap) }
        let runLoopSource = CFMachPortCreateRunLoopSource(nil, tap, 0)!
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        defer { CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes) }

        // Start with text to reproduce the reported text-clipping failure safely.
        board.clearContents()
        board.setString("Disposable text, not a file", forType: .string)
        lastCount = board.changeCount
        try finder("activate\nreveal POSIX file \"\(file.path)\"")
        try finder("set current view of front Finder window to \(view) view")
        try key(7)
        lastCount = board.changeCount
        try require(!focusRejected, "Finder's selected file was rejected by the focus guard.")
        let urls = board.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        try require(urls.map { $0.resolvingSymlinksInPath() } == [file.resolvingSymlinksInPath()], "Cmd+X did not copy the selected file URL.")
        try require(fm.fileExists(atPath: file.path), "Cmd+X must not remove the source before Paste.")
        try finder("open POSIX file \"\(destination.path)\"\nactivate")
        try finder("set current view of front Finder window to \(view) view")
        try key(9)
        lastCount = board.changeCount
        try require(!focusRejected, "Finder's destination was rejected by the focus guard.")
        let moved = destination.appendingPathComponent("probe.txt")
        try require(!fm.fileExists(atPath: file.path), "Cmd+V copied instead of moving: source still exists.")
        try require(try Data(contentsOf: moved) == content, "Moved file content differs.")
        try require(try fm.contentsOfDirectory(atPath: destination.path) == ["probe.txt"], "Unexpected paste output (such as a text clipping).")
        try finder("reveal POSIX file \"\(moved.path)\"")
        try key(8)
        lastCount = board.changeCount
        try finder("open POSIX file \"\(source.path)\"\nactivate")
        try key(9)
        lastCount = board.changeCount
        try require(fm.fileExists(atPath: moved.path), "Ordinary Cmd+C/Cmd+V unexpectedly moved the file.")
        try require(try Data(contentsOf: file) == content, "Ordinary Cmd+C/Cmd+V did not copy the file.")
        print("PASS (\(view) view): real Finder Cmd+X/Cmd+V moved the file, preserved its contents, and created no clipping.")
        print("PASS (\(view) view): ordinary Cmd+C/Cmd+V still copies.")
    }
}
