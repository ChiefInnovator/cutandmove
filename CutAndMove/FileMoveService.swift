import Foundation
import Darwin

nonisolated struct CutFile: Equatable, Sendable {
    let url: URL
    let device: Int32
    let inode: UInt64

    init(_ url: URL) throws {
        guard url.isFileURL, !url.lastPathComponent.isEmpty, url.path != "/" else { throw MoveFailure("Select files or folders to cut.") }
        // Resolve parent aliases, but move a symbolic link itself, not its target.
        self.url = url.deletingLastPathComponent().resolvingSymlinksInPath().appendingPathComponent(url.lastPathComponent)
        var info = stat()
        guard lstat(self.url.path, &info) == 0 else { throw MoveFailure("“\(url.lastPathComponent)” is no longer available.") }
        device = info.st_dev
        inode = info.st_ino
    }
}

nonisolated struct MoveFailure: LocalizedError {
    let errorDescription: String?
    init(_ message: String) { errorDescription = message }
}

nonisolated enum FileMoveService {
    struct Outcome: Sendable {
        let remaining: [CutFile]
        let moved: Int
        let error: String?
    }

    static func capture(_ urls: [URL]) throws -> [CutFile] {
        guard !urls.isEmpty, urls.count <= 1000 else { throw MoveFailure("Select between 1 and 1,000 items.") }
        let items = try urls.map(CutFile.init)
        guard Set(items.map(\.url)).count == items.count else { throw MoveFailure("The selection contains duplicate items.") }
        for item in items {
            guard !items.contains(where: { item.url.path.hasPrefix($0.url.path + "/") }) else {
                throw MoveFailure("Select a folder or its contents, not both.")
            }
        }
        return items
    }

    static func plan(_ items: [CutFile], destination: URL) throws -> [(CutFile, URL)] {
        guard !items.isEmpty, destination.isFileURL else { throw MoveFailure("Choose a destination folder.") }
        let folder = destination.resolvingSymlinksInPath()
        var directory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: folder.path, isDirectory: &directory), directory.boolValue else {
            throw MoveFailure("The destination folder is no longer available.")
        }
        var names = Set<String>()
        return try items.map { item in
            guard try CutFile(item.url) == item else { throw MoveFailure("“\(item.url.lastPathComponent)” changed since Cut. Select it again.") }
            guard folder != item.url, !folder.path.hasPrefix(item.url.path + "/") else { throw MoveFailure("A folder cannot be moved inside itself.") }
            let target = folder.appendingPathComponent(item.url.lastPathComponent)
            guard target != item.url else { throw MoveFailure("The items are already in this folder.") }
            var info = stat()
            guard lstat(target.path, &info) != 0, errno == ENOENT,
                  names.insert(target.lastPathComponent.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))).inserted else {
                throw MoveFailure("“\(target.lastPathComponent)” already exists at the destination. Nothing will be replaced.")
            }
            return (item, target)
        }
    }

    static func move(_ items: [CutFile], destination: URL) -> Outcome {
        var moved = 0
        do {
            let steps = try plan(items, destination: destination)
            for (item, target) in steps {
                guard try CutFile(item.url) == item else { throw MoveFailure("An item changed before it could be moved. Select it again.") }
                // Foundation refuses existing destinations and supports cross-volume moves.
                try FileManager.default.moveItem(at: item.url, to: target)
                moved += 1
            }
            return Outcome(remaining: [], moved: moved, error: nil)
        } catch {
            return Outcome(remaining: Array(items.dropFirst(moved)), moved: moved, error: error.localizedDescription)
        }
    }
}
