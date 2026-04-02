import Foundation
import Models

public final class LocalCacheService: StorageService, @unchecked Sendable {
    private let baseDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let fileManager = FileManager.default

    public init(baseDirectory: URL? = nil) {
        if let baseDirectory {
            self.baseDirectory = baseDirectory
        } else {
            let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            self.baseDirectory = appSupport.appendingPathComponent("MacTodo", isDirectory: true)
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func loadWorkspace(id: UUID) async throws -> Workspace {
        let url = fileURL(for: id)
        guard fileManager.fileExists(atPath: url.path) else {
            throw StorageError.workspaceNotFound(id)
        }
        let data = try Data(contentsOf: url)
        do {
            return try decoder.decode(Workspace.self, from: data)
        } catch {
            throw StorageError.decodingError(error.localizedDescription)
        }
    }

    public func saveWorkspace(_ workspace: Workspace) async throws {
        try ensureDirectoryExists()
        let data: Data
        do {
            data = try encoder.encode(workspace)
        } catch {
            throw StorageError.encodingError(error.localizedDescription)
        }
        let url = fileURL(for: workspace.id)
        try data.write(to: url, options: .atomic)
        try updateSyncMetadata(workspaceID: workspace.id)
    }

    public func listWorkspaces() async throws -> [UUID] {
        try ensureDirectoryExists()
        let contents = try fileManager.contentsOfDirectory(at: baseDirectory, includingPropertiesForKeys: nil)
        return contents.compactMap { url -> UUID? in
            let name = url.lastPathComponent
            guard name.hasPrefix("workspace-") && name.hasSuffix(".json") else { return nil }
            let uuidString = String(name.dropFirst("workspace-".count).dropLast(".json".count))
            return UUID(uuidString: uuidString)
        }
    }

    public func deleteWorkspace(id: UUID) async throws {
        let url = fileURL(for: id)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.removeItem(at: url)
        }
    }

    // MARK: - Sync Metadata

    public func lastSyncDate(for workspaceID: UUID) -> Date? {
        let metadata = loadSyncMetadata()
        return metadata[workspaceID.uuidString]
    }

    // MARK: - Helpers

    private func fileURL(for workspaceID: UUID) -> URL {
        baseDirectory.appendingPathComponent("workspace-\(workspaceID.uuidString).json")
    }

    private func ensureDirectoryExists() throws {
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try fileManager.createDirectory(at: baseDirectory, withIntermediateDirectories: true)
        }
    }

    private var syncMetadataURL: URL {
        baseDirectory.appendingPathComponent("sync-metadata.json")
    }

    private func loadSyncMetadata() -> [String: Date] {
        guard fileManager.fileExists(atPath: syncMetadataURL.path),
              let data = try? Data(contentsOf: syncMetadataURL),
              let metadata = try? decoder.decode([String: Date].self, from: data)
        else {
            return [:]
        }
        return metadata
    }

    private func updateSyncMetadata(workspaceID: UUID) throws {
        var metadata = loadSyncMetadata()
        metadata[workspaceID.uuidString] = Date()
        let data = try encoder.encode(metadata)
        try data.write(to: syncMetadataURL, options: .atomic)
    }
}
