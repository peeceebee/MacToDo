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

    init(sidebarItem: ContentView.SidebarItem, selectedTask: Binding<TodoItem?>, store: WorkspaceStore) {
        self.sidebarItem = sidebarItem
        _selectedTask = selectedTask
        _viewModel = State(initialValue: TaskListViewModel(store: store))
    }

    private var displayedItems: [TodoItem] {
        switch sidebarItem {
        case .todoList(let project):
            return viewModel.filteredItems.filter { $0.projectID == project.id }
        default:
            return viewModel.filteredItems
        }
    }

    private var currentProjectID: UUID? {
        if case .todoList(let p) = sidebarItem { return p.id }
        return nil
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
        case .todoList(let p): p.name
        default: "Tasks"
        }
    }

    private var projectIDForNewTask: UUID? {
        if case .todoList(let p) = sidebarItem { return p.id }
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
