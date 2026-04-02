import SwiftUI
import Models
import Storage
import ViewModels

@main
struct MacTodoMacApp: App {
    @State private var syncEngine: SyncEngine
    @State private var localCache: LocalCacheService
    @State private var workspaceID: UUID

    init() {
        let localCache = LocalCacheService()
        let workspaceID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

        let remote: StorageService
        if let config = AzureConfiguration.fromEnvironment() {
            remote = AzureBlobStorageService(config: config)
        } else {
            remote = localCache
        }

        self._syncEngine = State(initialValue: SyncEngine(remote: remote, local: localCache))
        self._localCache = State(initialValue: localCache)
        self._workspaceID = State(initialValue: workspaceID)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(syncEngine: syncEngine, workspaceID: workspaceID, localCache: localCache)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("New Task") {
                    NotificationCenter.default.post(name: .newTask, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)

                Button("New Project") {
                    NotificationCenter.default.post(name: .newProject, object: nil)
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsPane(syncEngine: syncEngine, workspaceID: workspaceID, localCache: localCache)
        }
    }
}

extension Notification.Name {
    static let newTask = Notification.Name("MacTodo.newTask")
    static let newProject = Notification.Name("MacTodo.newProject")
}
