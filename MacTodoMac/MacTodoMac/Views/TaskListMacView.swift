import SwiftUI
import Models
import Storage
import ViewModels

struct TaskListMacView: View {
    let sidebarItem: ContentView.SidebarItem
    @Binding var selectedTask: TodoItem?
    @State private var viewModel: TaskListViewModel
    @State private var showingAddTask = false
    @State private var newTaskTitle = ""

    init(sidebarItem: ContentView.SidebarItem, selectedTask: Binding<TodoItem?>, syncEngine: SyncEngine, workspaceID: UUID) {
        self.sidebarItem = sidebarItem
        _selectedTask = selectedTask
        _viewModel = State(initialValue: TaskListViewModel(syncEngine: syncEngine, workspaceID: workspaceID))
    }

    private var displayedItems: [TodoItem] {
        let calendar = Calendar.current
        switch sidebarItem {
        case .allTasks:
            return viewModel.filteredItems
        case .today:
            return viewModel.filteredItems.filter { item in
                guard let dueDate = item.dueDate else { return false }
                return calendar.isDateInToday(dueDate)
            }
        case .upcoming:
            return viewModel.filteredItems.filter { item in
                guard let dueDate = item.dueDate else { return false }
                return dueDate > Date()
            }
        case .project(let project):
            return viewModel.filteredItems.filter { $0.projectID == project.id }
        }
    }

    var body: some View {
        List(displayedItems, selection: $selectedTask) { item in
            HStack {
                Button {
                    Task { await viewModel.toggleCompletion(item) }
                } label: {
                    Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(item.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)

                VStack(alignment: .leading) {
                    Text(item.title)
                        .strikethrough(item.isCompleted)
                    if let dueDate = item.dueDate {
                        Text(dueDate, style: .date)
                            .font(.caption)
                            .foregroundStyle(dueDate < Date() && !item.isCompleted ? .red : .secondary)
                    }
                }

                Spacer()

                if item.priority != .none {
                    Text(item.priority.label)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(priorityColor(item.priority).opacity(0.2))
                        .foregroundStyle(priorityColor(item.priority))
                        .clipShape(Capsule())
                }
            }
            .tag(item)
        }
        .navigationTitle(sidebarTitle)
        .searchable(text: $viewModel.searchText, prompt: "Search tasks")
        .toolbar {
            ToolbarItemGroup {
                Toggle(isOn: $viewModel.showCompleted) {
                    Image(systemName: viewModel.showCompleted ? "eye.fill" : "eye.slash")
                }
                .help("Show completed tasks")

                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus")
                }
                .help("New task")
            }
        }
        .alert("New Task", isPresented: $showingAddTask) {
            TextField("Task title", text: $newTaskTitle)
            Button("Add") {
                guard !newTaskTitle.isEmpty else { return }
                Task {
                    await viewModel.addTask(title: newTaskTitle, projectID: projectIDForNewTask)
                    newTaskTitle = ""
                }
            }
            Button("Cancel", role: .cancel) { newTaskTitle = "" }
        }
        .task {
            await viewModel.loadTasks()
        }
        .onReceive(NotificationCenter.default.publisher(for: .newTask)) { _ in
            showingAddTask = true
        }
        .onDeleteCommand {
            if let selected = selectedTask {
                Task {
                    await viewModel.deleteTask(selected)
                    selectedTask = nil
                }
            }
        }
    }

    private var sidebarTitle: String {
        switch sidebarItem {
        case .allTasks: "All Tasks"
        case .today: "Today"
        case .upcoming: "Upcoming"
        case .project(let p): p.name
        }
    }

    private var projectIDForNewTask: UUID? {
        if case .project(let p) = sidebarItem { return p.id }
        return nil
    }

    private func priorityColor(_ priority: Priority) -> Color {
        switch priority {
        case .none: .clear
        case .low: .blue
        case .medium: .yellow
        case .high: .orange
        case .urgent: .red
        }
    }
}
