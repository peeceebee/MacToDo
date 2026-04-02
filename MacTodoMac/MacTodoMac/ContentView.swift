import SwiftUI
import Models
import Storage
import ViewModels

struct ContentView: View {
    let syncEngine: SyncEngine
    let workspaceID: UUID
    let localCache: LocalCacheService

    @State private var selectedSidebarItem: SidebarItem? = .allTasks
    @State private var selectedTask: TodoItem?

    enum SidebarItem: Hashable {
        case allTasks
        case today
        case upcoming
        case project(Project)
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedItem: $selectedSidebarItem,
                syncEngine: syncEngine,
                workspaceID: workspaceID
            )
        } content: {
            TaskListMacView(
                sidebarItem: selectedSidebarItem ?? .allTasks,
                selectedTask: $selectedTask,
                syncEngine: syncEngine,
                workspaceID: workspaceID
            )
        } detail: {
            if let task = selectedTask {
                TaskDetailMacView(
                    item: task,
                    syncEngine: syncEngine,
                    workspaceID: workspaceID
                )
            } else {
                ContentUnavailableView("Select a Task", systemImage: "checklist", description: Text("Choose a task from the list to view its details."))
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}
