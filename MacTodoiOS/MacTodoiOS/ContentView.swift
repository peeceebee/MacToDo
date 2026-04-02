import SwiftUI
import Models
import Storage
import ViewModels

struct ContentView: View {
    let store: WorkspaceStore

    var body: some View {
        TabView {
            Tab("Tasks", systemImage: "checklist") {
                NavigationStack {
                    TaskListView(store: store)
                }
            }

            Tab("Projects", systemImage: "folder.fill") {
                NavigationStack {
                    ProjectListView(store: store)
                }
            }

            Tab("Settings", systemImage: "gear") {
                NavigationStack {
                    SettingsView(store: store)
                }
            }
        }
    }
}
