import SwiftUI
import Models
import Storage
import ViewModels

@main
struct MacTodoMacApp: App {
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
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .newTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New ToDo List") {
                    NotificationCenter.default.post(name: .newProject, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsPane(store: store)
        }
    }
}

extension Notification.Name {
    static let newTask = Notification.Name("MacTodo.newTask")
    static let newProject = Notification.Name("MacTodo.newProject")
}
