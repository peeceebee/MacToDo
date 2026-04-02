import SwiftUI
import Models
import Storage
import ViewModels

struct ContentView: View {
    let store: WorkspaceStore

    var body: some View {
        TabView {
            Tab("Shopping", systemImage: "cart.fill") {
                NavigationStack {
                    ShoppingListiOSView(store: store)
                }
            }

            Tab("Schedule", systemImage: "calendar") {
                NavigationStack {
                    ScheduleiOSView()
                }
            }

            Tab("ToDo Lists", systemImage: "folder.fill") {
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
