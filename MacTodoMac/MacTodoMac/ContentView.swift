import SwiftUI
import Models
import Storage
import ViewModels

struct ContentView: View {
    let store: WorkspaceStore

    @State private var selectedSidebarItem: SidebarItem? = .todaysTodo
    @State private var selectedTask: TodoItem?

    enum SidebarItem: Hashable {
        case todaysTodo
        case pastDueDo
        case shoppingList
        case schedule
        case todoList(Project)
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedItem: $selectedSidebarItem,
                store: store
            )
        } content: {
            switch selectedSidebarItem {
            case .shoppingList:
                ShoppingListView(store: store)
            case .schedule:
                ScheduleView(store: store)
            case .todaysTodo:
                TodayTasksView(mode: .today, selectedTask: $selectedTask, store: store)
            case .pastDueDo:
                TodayTasksView(mode: .pastDue, selectedTask: $selectedTask, store: store)
            case .todoList(let project):
                TaskListMacView(
                    sidebarItem: .todoList(project),
                    selectedTask: $selectedTask,
                    store: store
                )
            case nil:
                ContentUnavailableView("Select an Item", systemImage: "sidebar.left", description: Text("Choose from the sidebar."))
            }
        } detail: {
            if let task = selectedTask {
                TaskDetailMacView(
                    item: task,
                    store: store
                )
                .id(task.id)
            } else {
                ContentUnavailableView("Select a Task", systemImage: "checklist", description: Text("Choose a task from the list to view its details."))
            }
        }
        .frame(minWidth: 800, minHeight: 500)
    }
}
