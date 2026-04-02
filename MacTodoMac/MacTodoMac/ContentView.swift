import SwiftUI
import Models
import Storage
import ViewModels

struct ContentView: View {
    let store: WorkspaceStore

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
                store: store
            )
        } content: {
            TaskListMacView(
                sidebarItem: selectedSidebarItem ?? .allTasks,
                selectedTask: $selectedTask,
                store: store
            )
        } detail: {
            if let task = selectedTask {
                TaskDetailMacView(
                    item: task,
                    store: store
                )
                .id(task.id) // Force view recreation when selection changes
            } else {
                ContentUnavailableView("Select a Task", systemImage: "checklist", description: Text("Choose a task from the list to view its details."))
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}
