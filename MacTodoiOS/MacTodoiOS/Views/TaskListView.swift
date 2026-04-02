import SwiftUI
import Models
import Storage
import ViewModels

struct TaskListView: View {
    @State private var viewModel: TaskListViewModel
    @State private var newTaskTitle = ""
    @State private var showingAddTask = false

    init(syncEngine: SyncEngine, workspaceID: UUID) {
        _viewModel = State(initialValue: TaskListViewModel(syncEngine: syncEngine, workspaceID: workspaceID))
    }

    var body: some View {
        List {
            ForEach(viewModel.filteredItems) { item in
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
        .navigationTitle("Tasks")
        .navigationDestination(for: TodoItem.self) { item in
            if let workspace = viewModel.workspace {
                TaskDetailView(item: item, workspace: workspace, syncEngine: viewModel.filteredItems.isEmpty ? nil : nil)
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search tasks")
        .refreshable {
            await viewModel.loadTasks()
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddTask = true
                } label: {
                    Image(systemName: "plus")
                }
            }
            ToolbarItem(placement: .secondaryAction) {
                Toggle("Show Completed", isOn: $viewModel.showCompleted)
            }
        }
        .alert("New Task", isPresented: $showingAddTask) {
            TextField("Task title", text: $newTaskTitle)
            Button("Add") {
                guard !newTaskTitle.isEmpty else { return }
                Task {
                    await viewModel.addTask(title: newTaskTitle)
                    newTaskTitle = ""
                }
            }
            Button("Cancel", role: .cancel) { newTaskTitle = "" }
        }
        .task {
            await viewModel.loadTasks()
        }
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
