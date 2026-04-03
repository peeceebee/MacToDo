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
    @State private var isEditingName = false
    @State private var editingName = ""
    private let store: WorkspaceStore

    init(sidebarItem: ContentView.SidebarItem, selectedTask: Binding<TodoItem?>, store: WorkspaceStore) {
        self.sidebarItem = sidebarItem
        self.store = store
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

    private var currentProject: Project? {
        if case .todoList(let p) = sidebarItem { return p }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header bar: editable name on left, icons on right
            headerBar
                .padding(.horizontal)
                .padding(.vertical, 8)

            Divider()

            // Task list
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
                        HStack(spacing: 2) {
                            if !item.assigneePrefix.isEmpty {
                                Text(item.assigneePrefix)
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.title)
                        }
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

                    Button {
                        Task {
                            await viewModel.deleteTask(item)
                            if selectedTask?.id == item.id { selectedTask = nil }
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Delete task")
                }
                .tag(item)
            }
            .searchable(text: $viewModel.searchText, prompt: "Search tasks")
        }
        .navigationBarBackButtonHidden(true)
        .alert("New Task", isPresented: $showingAddTask) {
            TextField("Task title", text: $newTaskTitle)
            Button("Add") {
                guard !newTaskTitle.isEmpty else { return }
                Task {
                    await viewModel.addTask(title: newTaskTitle, projectID: currentProject?.id)
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

    @ViewBuilder
    private var headerBar: some View {
        HStack {
            // Editable todo list name
            if isEditingName {
                TextField("ToDo List name", text: $editingName, onCommit: {
                    saveEditedName()
                })
                .textFieldStyle(.roundedBorder)
                .font(.title2.weight(.semibold))
                .frame(maxWidth: 300)
                .onExitCommand { cancelEditing() }
            } else {
                Text(currentProject?.name ?? "Tasks")
                    .font(.title2.weight(.semibold))
                    .onTapGesture {
                        if let project = currentProject {
                            editingName = project.name
                            isEditingName = true
                        }
                    }
            }

            Spacer()

            // Show completed toggle
            Button {
                viewModel.showCompleted.toggle()
            } label: {
                Image(systemName: viewModel.showCompleted ? "eye.fill" : "eye.slash")
            }
            .buttonStyle(.borderless)
            .help(viewModel.showCompleted ? "Hide completed" : "Show completed")

            // New task button
            Button {
                showingAddTask = true
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("New task")
        }
    }

    private func saveEditedName() {
        guard let project = currentProject else { return }
        let newName = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else {
            cancelEditing()
            return
        }
        var updated = project
        updated.name = newName
        Task { await store.updateProject(updated) }
        isEditingName = false
    }

    private func cancelEditing() {
        isEditingName = false
        editingName = ""
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
