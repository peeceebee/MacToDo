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

    private let store: WorkspaceStore
    private let localCache: LocalCacheService

    public init(store: WorkspaceStore, localCache: LocalCacheService) {
        self.store = store
        self.localCache = localCache
    }

    public func refresh() async {
        let status = await store.syncStatus
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
        lastSyncDate = localCache.lastSyncDate(for: store.workspaceID)
    }

    public func syncNow() async {
        isSyncing = true
        syncStatusText = "Syncing..."
        await store.sync()
        await refresh()
    }

    public func exportData() async -> Data? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try? encoder.encode(store.workspace)
    }
}
