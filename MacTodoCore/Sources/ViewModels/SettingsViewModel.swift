import Foundation
import Models
import Storage

@MainActor
@Observable
public final class SettingsViewModel {
    public var syncStatusText: String = "Idle"
    public var lastSyncDate: Date?
    public var storageAccountName: String = ""
    public var isSyncing: Bool = false

    private let syncEngine: SyncEngine
    private let workspaceID: UUID
    private let localCache: LocalCacheService

    public init(syncEngine: SyncEngine, workspaceID: UUID, localCache: LocalCacheService) {
        self.syncEngine = syncEngine
        self.workspaceID = workspaceID
        self.localCache = localCache
    }

    public func refresh() async {
        let status = await syncEngine.syncStatus
        switch status {
        case .idle:
            syncStatusText = "Synced"
            isSyncing = false
        case .syncing:
            syncStatusText = "Syncing..."
            isSyncing = true
        case .error(let msg):
            syncStatusText = msg
            isSyncing = false
        }
        lastSyncDate = localCache.lastSyncDate(for: workspaceID)
    }

    public func syncNow() async {
        isSyncing = true
        syncStatusText = "Syncing..."
        await syncEngine.sync(workspaceID: workspaceID)
        await refresh()
    }

    public func exportData() async -> Data? {
        let ws = await syncEngine.loadWorkspace(id: workspaceID)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(ws)
    }
}
