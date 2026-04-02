import Foundation
import Models

public enum SyncStatus: Sendable {
    case idle
    case syncing
    case error(String)
}

public actor SyncEngine {
    private let remote: StorageService
    private let local: LocalCacheService
    private var _syncStatus: SyncStatus = .idle

    public var syncStatus: SyncStatus { _syncStatus }

    public init(remote: StorageService, local: LocalCacheService) {
        self.remote = remote
        self.local = local
    }

    public func loadWorkspace(id: UUID) async -> Workspace {
        _syncStatus = .syncing
        do {
            let remoteWorkspace = try await remote.loadWorkspace(id: id)
            try await local.saveWorkspace(remoteWorkspace)
            _syncStatus = .idle
            return remoteWorkspace
        } catch {
            do {
                let localWorkspace = try await local.loadWorkspace(id: id)
                _syncStatus = .error("Using cached data: \(error.localizedDescription)")
                return localWorkspace
            } catch {
                _syncStatus = .error(error.localizedDescription)
                return Workspace(id: id)
            }
        }
    }

    public func saveWorkspace(_ workspace: Workspace) async {
        var workspace = workspace
        workspace.touch()

        do {
            try await local.saveWorkspace(workspace)
        } catch {
            _syncStatus = .error("Local save failed: \(error.localizedDescription)")
        }

        _syncStatus = .syncing
        do {
            try await remote.saveWorkspace(workspace)
            _syncStatus = .idle
        } catch {
            _syncStatus = .error("Sync pending: \(error.localizedDescription)")
        }
    }

    public func sync(workspaceID: UUID) async {
        _syncStatus = .syncing
        do {
            let remoteWorkspace = try await remote.loadWorkspace(id: workspaceID)
            let localWorkspace = try? await local.loadWorkspace(id: workspaceID)

            if let localWorkspace, localWorkspace.lastModified > remoteWorkspace.lastModified {
                try await remote.saveWorkspace(localWorkspace)
            } else {
                try await local.saveWorkspace(remoteWorkspace)
            }
            _syncStatus = .idle
        } catch is StorageError {
            if let localWorkspace = try? await local.loadWorkspace(id: workspaceID) {
                do {
                    try await remote.saveWorkspace(localWorkspace)
                    _syncStatus = .idle
                } catch {
                    _syncStatus = .error("Sync failed: \(error.localizedDescription)")
                }
            } else {
                _syncStatus = .error("No data available")
            }
        } catch {
            _syncStatus = .error("Sync failed: \(error.localizedDescription)")
        }
    }
}
