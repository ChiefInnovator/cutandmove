import Cocoa
import Testing
@testable import CutAndMove

@MainActor
struct FinderIntegrationTests {
    @Test func finderMenuTagsPreserveActionSnapshots() {
        var actions = FinderMenuActions()
        let first = FinderRequest(action: .cut, urls: [URL(fileURLWithPath: "/first")])
        let second = FinderRequest(action: .cut, urls: [URL(fileURLWithPath: "/second")])
        let firstTag = actions.register(first)
        let secondTag = actions.register(second)
        #expect(firstTag != secondTag)
        #expect(actions.request(for: firstTag)?.urls == first.urls)
        #expect(actions.request(for: secondTag)?.urls == second.urls)
        #expect(actions.request(for: 0) == nil)
        for _ in 0..<256 { _ = actions.register(second) }
        #expect(actions.request(for: firstTag) == nil)
        let laterTag = actions.register(second)
        #expect(laterTag > secondTag)
    }

    func fixture() throws -> URL {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("cutandmove-unit-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root.appendingPathComponent("source"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("target"), withIntermediateDirectories: true)
        try Data("original".utf8).write(to: root.appendingPathComponent("source/a.txt"))
        return root
    }

    @Test func menuMovePreservesContentsAndRemovesSource() throws {
        let root = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source/a.txt")
        let result = FileMoveService.move(try FileMoveService.capture([source]), destination: root.appendingPathComponent("target"))
        #expect(result.error == nil)
        #expect(result.moved == 1)
        #expect(result.remaining.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: source.path))
        #expect(try Data(contentsOf: root.appendingPathComponent("target/a.txt")) == Data("original".utf8))
    }

    @Test func collisionRejectsWholeBatchWithoutOverwriting() throws {
        let root = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let second = root.appendingPathComponent("source/b.txt")
        try Data("second".utf8).write(to: second)
        try Data("existing".utf8).write(to: root.appendingPathComponent("target/b.txt"))
        let items = try FileMoveService.capture([root.appendingPathComponent("source/a.txt"), second])
        let result = FileMoveService.move(items, destination: root.appendingPathComponent("target"))
        #expect(result.error != nil)
        #expect(result.moved == 0)
        #expect(result.remaining == items)
        #expect(try Data(contentsOf: root.appendingPathComponent("target/b.txt")) == Data("existing".utf8))
        #expect(FileManager.default.fileExists(atPath: items[0].url.path))
    }

    @Test func replacedSourceIsNotMoved() throws {
        let root = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source/a.txt")
        let items = try FileMoveService.capture([source])
        let replacement = root.appendingPathComponent("replacement")
        try Data("replacement".utf8).write(to: replacement)
        try FileManager.default.removeItem(at: source)
        try FileManager.default.moveItem(at: replacement, to: source)
        let result = FileMoveService.move(items, destination: root.appendingPathComponent("target"))
        #expect(result.error != nil)
        #expect(result.moved == 0)
        #expect(try Data(contentsOf: source) == Data("replacement".utf8))
    }

    @Test func symbolicLinkMovesTheLinkNotItsTarget() throws {
        let root = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let original = root.appendingPathComponent("source/a.txt")
        let link = root.appendingPathComponent("source/link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: original)
        let result = FileMoveService.move(try FileMoveService.capture([link]), destination: root.appendingPathComponent("target"))
        #expect(result.error == nil)
        #expect(FileManager.default.fileExists(atPath: original.path))
        #expect(try FileManager.default.destinationOfSymbolicLink(atPath: root.appendingPathComponent("target/link").path) == original.path)
    }

    @Test func unsafeAndAmbiguousDestinationsAreRejected() throws {
        let root = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let source = root.appendingPathComponent("source")
        let file = source.appendingPathComponent("a.txt")
        #expect(throws: (any Error).self) { try FileMoveService.capture([]) }
        #expect(throws: (any Error).self) { try FileMoveService.capture([file, file]) }
        #expect(throws: (any Error).self) { try FileMoveService.capture([source, file]) }
        let items = try FileMoveService.capture([source])
        #expect(FileMoveService.move(items, destination: source).error != nil)
        let files = try FileMoveService.capture([file])
        #expect(FileMoveService.move(files, destination: source).error != nil)
        #expect(FileMoveService.move(files, destination: file).error != nil)
        #expect(FileMoveService.move(files, destination: URL(string: "https://example.com")!).error != nil)
    }

    @Test func finderRequestsAndStatusRoundTripAcrossStoreInstances() throws {
        let root = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let host = try FinderBridge(directory: root)
        let finder = try FinderBridge(directory: root)
        let cut = FinderCut(id: UUID(), urls: [root.appendingPathComponent("source/a.txt")], clipboard: 42)
        try host.publish(FinderStatus(cut: cut))
        #expect(try finder.status().cut == cut)
        let request = FinderRequest(action: .move, urls: [root.appendingPathComponent("target")], cutID: cut.id)
        try finder.send(request)
        let commands = try host.requests()
        #expect(commands.count == 1)
        #expect(commands[0].1.cutID == cut.id)
        try host.acknowledge(commands[0].0)
        #expect(try host.requests().isEmpty)
        #expect(throws: (any Error).self) { try host.acknowledge(root.appendingPathComponent("source/a.txt")) }
    }

    @Test func menuCutCanBeCompletedByKeyboardPaste() {
        var state = ShortcutState()
        state.armCut(clipboard: 42)
        let paste = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true)!
        paste.flags = .maskCommand
        let pass = state.process(paste, fileContext: true, clipboard: 42, hasFiles: true)
        #expect(pass)
        #expect(paste.flags.contains(.maskAlternate))
        #expect(!state.isCutModeActive)
    }

    @Test func malformedRequestDoesNotBlockLaterActions() throws {
        let root = try fixture()
        defer { try? FileManager.default.removeItem(at: root) }
        let bridge = try FinderBridge(directory: root)
        let malformed = bridge.directory.appendingPathComponent("requests/broken.json")
        try Data("not JSON".utf8).write(to: malformed)
        try bridge.send(FinderRequest(action: .cancel))
        #expect(throws: (any Error).self) { try bridge.requests() }
        #expect(!FileManager.default.fileExists(atPath: malformed.path))
        #expect(try bridge.requests().count == 1)
        #expect(try FileManager.default.contentsOfDirectory(atPath: bridge.directory.appendingPathComponent("rejected").path).count == 1)
    }

    @Test func destinationPermissionFailureIsNotReportedAsCollision() throws {
        guard geteuid() != 0 else { return }
        let root = try fixture()
        let target = root.appendingPathComponent("target")
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: target.path)
            try? FileManager.default.removeItem(at: root)
        }
        try FileManager.default.setAttributes([.posixPermissions: 0], ofItemAtPath: target.path)
        let source = root.appendingPathComponent("source/a.txt")
        let result = FileMoveService.move(try FileMoveService.capture([source]), destination: target)
        #expect(result.moved == 0)
        #expect(result.error != nil)
        #expect(result.error?.contains("already exists") == false)
        #expect(FileManager.default.fileExists(atPath: source.path))
    }

    @Test(arguments: [CGKeyCode(7), 9])
    func busyMovePreservesTextKeysAndConsumesOnlyBlockedPairs(key: CGKeyCode) {
        var state = ShortcutState()
        func event(down: Bool) -> CGEvent {
            let value = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: down)!
            value.flags = .maskCommand
            return value
        }
        #expect({ state.process(event(down: true), fileContext: false, clipboard: 0, hasFiles: false, fileMoveInProgress: true) }())
        // The event tap skips AX for key-up and supplies true; it must still pass.
        #expect({ state.process(event(down: false), fileContext: true, clipboard: 0, hasFiles: false, fileMoveInProgress: true) }())
        #expect({ !state.process(event(down: true), fileContext: true, clipboard: 0, hasFiles: true, fileMoveInProgress: true) }())
        let up = event(down: false)
        up.flags = []
        #expect({ !state.process(up, fileContext: true, clipboard: 0, hasFiles: true, fileMoveInProgress: false) }())
        #expect({ state.process(event(down: false), fileContext: true, clipboard: 0, hasFiles: false, fileMoveInProgress: true) }())
    }
}
