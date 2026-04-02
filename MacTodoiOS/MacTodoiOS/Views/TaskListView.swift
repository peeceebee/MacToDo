import SwiftUI
import Models
import Storage
import ViewModels

struct TaskListView: View {
    @State private var viewModel: TaskListViewModel
    @State private var newTaskTitle = ""
    @State private var showingAddTask = false
    @State private var isEditingName = false
    @State private var editingName = ""
    private let store: WorkspaceStore
    private let project: Project

    init(project: Project, store: WorkspaceStore) {
        self.project = project
        self.store = store
        _viewModel = State(initialValue: TaskListViewModel(store: store))
    }

    private var displayedItems: [TodoItem] {
        viewModel.filteredItems.filter { $0.projectID == project.id }
    }

    var body: some View {
        List {
            ForEach(displayedItems) { item in
                NavigationLink(value: item) {
                    TaskRow(item: item)
                }
                .swipeActions(edge: .leading) {
                    Button {
                        Task { await viewModel.toggleCompletion(item) }
                    } label: {
                        Label(item.isCompleted ? "Undo" : "Done", systemImage: item.isCompleted ? "arrow.uturn.backward" : "checkmark")
                    }
                    .tint(item.isCompleted ? .orange : .green)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        Task { await viewModel.deleteTask(item) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle(isEditingName ? "" : project.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: TodoItem.self) { item in
            TaskDetailView(item: item, store: store)
        }
        .searchable(text: $viewModel.searchText, prompt: "Search tasks")
        .refreshable {
            await viewModel.loadTasks()
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isEditingName {
                    TextField("ToDo List name", text: $editingName)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: 200)
                        .onSubmit { saveEditedName() }
                } else {
                    Text(project.name)
                        .font(.headline)
                        .onTapGesture(count: 1) {
                            editingName = project.name
                            isEditingName = true
                        }
                }
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    viewModel.showCompleted.toggle()
                } label: {
                    Image(systemName: viewModel.showCompleted ? "eye.fill" : "eye.slash")
                }

                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Task", isPresented: $showingAddTask) {
            TextField("Task title", text: $newTaskTitle)
            Button("Add") {
                guard !newTaskTitle.isEmpty else { return }
                Task {
                    await viewModel.addTask(title: newTaskTitle, projectID: project.id)
                    newTaskTitle = ""
                }
            }
            Button("Cancel", role: .cancel) { newTaskTitle = "" }
        }
    }

    private func saveEditedName() {
        let newName = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !newName.isEmpty else {
            isEditingName = false
            return
        }
        var updated = project
        updated.name = newName
        Task { await store.updateProject(updated) }
        isEditingName = false
    }
}

private struct TaskRow: View {
    let item: TodoItem

    var body: some View {
        HStack {
            Image(systemName: item.isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(item.isCompleted ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .strikethrough(item.isCompleted)
                    .foregroundStyle(item.isCompleted ? .secondary : .primary)

                if let dueDate = item.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(dueDate < Date() && !item.isCompleted ? .red : .secondary)
                }
            }

            Spacer()

            if item.priority != .none {
                PriorityBadge(priority: item.priority)
            }
        }
    }
}

private struct PriorityBadge: View {
    let priority: Priority

    var color: Color {
        switch priority {
        case .none: .clear
        case .low: .blue
        case .medium: .yellow
        case .high: .orange
        case .urgent: .red
        }
    }

    var body: some View {
        Text(priority.label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}
