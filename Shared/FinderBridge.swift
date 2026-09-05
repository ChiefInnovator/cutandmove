import Foundation

struct FinderCut: Codable, Equatable {
    let id: UUID
    let urls: [URL]
    let clipboard: Int
}

struct FinderStatus: Codable, Equatable {
    var cut: FinderCut?
    var message: String?
    var busy = false
    var updated = Date()
}

struct FinderRequest: Codable {
    enum Action: String, Codable { case cut, move, cancel }
    var id = UUID()
    var created = Date()
    let action: Action
    var urls: [URL] = []
    var cutID: UUID?
}

/// Finder transports menu tags, not arbitrary Swift representedObject values.
struct FinderMenuActions {
    private var nextTag = 1
    private var commands: [Int: FinderRequest] = [:]

    mutating func register(_ request: FinderRequest) -> Int {
        // Bound retained snapshots, but never reuse tags: an older open menu
        // must fail closed rather than dispatching a newer action's selection.
        if commands.count >= 256 { commands.removeAll() }
        let tag = nextTag
        nextTag += 1
        commands[tag] = request
        return tag
    }

    func request(for tag: Int) -> FinderRequest? { commands[tag] }
}

/// Atomic, local IPC between our sandboxed Finder extension and its containing app.
/// Only the containing app writes status; each request has its own immutable file.
struct FinderBridge {
    static let group = "FS6453639M.CutAndMove"
    let directory: URL

    init(directory: URL? = nil) throws {
        guard let root = directory ?? FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.group) else {
            throw CocoaError(.fileNoSuchFile)
        }
        self.directory = root.appendingPathComponent("FinderBridge", isDirectory: true)
        try FileManager.default.createDirectory(at: self.directory.appendingPathComponent("requests"), withIntermediateDirectories: true)
    }

    func status() throws -> FinderStatus {
        let file = directory.appendingPathComponent("status.json")
        guard FileManager.default.fileExists(atPath: file.path) else { return FinderStatus() }
        return try JSONDecoder().decode(FinderStatus.self, from: Data(contentsOf: file))
    }

    func publish(_ status: FinderStatus) throws {
        try JSONEncoder().encode(status).write(to: directory.appendingPathComponent("status.json"), options: .atomic)
    }

    func folders() throws -> [URL] {
        let file = directory.appendingPathComponent("folders.json")
        guard FileManager.default.fileExists(atPath: file.path) else { return [] }
        return try JSONDecoder().decode([URL].self, from: Data(contentsOf: file))
    }

    func setFolders(_ urls: [URL]) throws {
        try JSONEncoder().encode(urls).write(to: directory.appendingPathComponent("folders.json"), options: .atomic)
    }

    func send(_ request: FinderRequest) throws {
        let file = directory.appendingPathComponent("requests/\(request.id.uuidString).json")
        try JSONEncoder().encode(request).write(to: file, options: .atomic)
    }

    func requests() throws -> [(URL, FinderRequest)] {
        let files = try FileManager.default.contentsOfDirectory(at: directory.appendingPathComponent("requests"), includingPropertiesForKeys: [.fileSizeKey])
        return try files.filter { $0.pathExtension == "json" }.map { file in
            do {
                guard (try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? Int.max) <= 2_000_000 else { throw CocoaError(.fileReadTooLarge) }
                return (file, try JSONDecoder().decode(FinderRequest.self, from: Data(contentsOf: file)))
            } catch {
                // A malformed request must not permanently block every later action.
                let rejected = directory.appendingPathComponent("rejected", isDirectory: true)
                try FileManager.default.createDirectory(at: rejected, withIntermediateDirectories: true)
                try FileManager.default.moveItem(at: file, to: rejected.appendingPathComponent(UUID().uuidString + ".json"))
                throw error
            }
        }.sorted { $0.1.created < $1.1.created }
    }

    func acknowledge(_ file: URL) throws {
        guard file.deletingLastPathComponent().standardizedFileURL.path == directory.appendingPathComponent("requests").standardizedFileURL.path else { throw CocoaError(.fileWriteInvalidFileName) }
        try FileManager.default.removeItem(at: file)
    }
}
