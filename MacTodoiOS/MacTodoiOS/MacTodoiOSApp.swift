import SwiftUI
import Models
import Storage
import ViewModels

@main
struct MacTodoiOSApp: App {
    @State private var store: WorkspaceStore

    init() {
        let localCache = LocalCacheService()
        let workspaceID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        let remote: StorageService
        if let config = AzureConfiguration.fromEnvironment() {
            remote = AzureBlobStorageService(config: config)
        } else {
            remote = localCache
        }

        let syncEngine = SyncEngine(remote: remote, local: localCache)
        self._store = State(initialValue: WorkspaceStore(syncEngine: syncEngine, workspaceID: workspaceID))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
                .task { await store.load() }
        }
    }
}
