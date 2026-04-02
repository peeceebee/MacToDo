import SwiftUI
import Models
import Storage
import ViewModels

struct ContentView: View {
    let syncEngine: SyncEngine
    let workspaceID: UUID
    let localCache: LocalCacheService

    var body: some View {
        TabView {
            Tab("Tasks", systemImage: "checklist") {
                NavigationStack {
                    TaskListView(syncEngine: syncEngine, workspaceID: workspaceID)
                }
            }

            Tab("Projects", systemImage: "folder.fill") {
                NavigationStack {
                    ProjectListView(syncEngine: syncEngine, workspaceID: workspaceID)
                }
            }

            Tab("Settings", systemImage: "gear") {
                NavigationStack {
                    SettingsView(syncEngine: syncEngine, workspaceID: workspaceID, localCache: localCache)
                }
            }
        }
    }
}
