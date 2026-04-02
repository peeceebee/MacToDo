import Foundation
import Models
import Storage

public final class MockStorageService: StorageService, @unchecked Sendable {
    private var store: [UUID: Workspace] = [:]

    public init() {}

    public func loadWorkspace(id: UUID) async throws -> Workspace {
        guard let ws = store[id] else {
            throw StorageError.workspaceNotFound(id)
        }
        return ws
    }

    public func saveWorkspace(_ workspace: Workspace) async throws {
        store[workspace.id] = workspace
    }

    public func listWorkspaces() async throws -> [UUID] {
        Array(store.keys)
    }

    public func deleteWorkspace(id: UUID) async throws {
        store.removeValue(forKey: id)
    }

    // Test helpers
    public func reset() {
        store.removeAll()
    }

    public var storedWorkspaces: [UUID: Workspace] { store }
}
