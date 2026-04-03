import SwiftUI
import Models
import Storage
import ViewModels

struct TodayTasksView: View {
    enum Mode {
        case today
        case pastDue
    }

    let mode: Mode
    @Binding var selectedTask: TodoItem?
    private let store: WorkspaceStore

    init(mode: Mode, selectedTask: Binding<TodoItem?>, store: WorkspaceStore) {
        self.mode = mode
        _selectedTask = selectedTask
        self.store = store
    }

    private var filteredItems: [TodoItem] {
        let calendar = Calendar.current
        let now = Date()
        return store.items.filter { item in
            guard !item.isCompleted, let dueDate = item.dueDate else { return false }
            switch mode {
            case .today:
                return calendar.isDateInToday(dueDate)
            case .pastDue:
                return dueDate < calendar.startOfDay(for: now)
            }
        }
        .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }

    private func projectName(for item: TodoItem) -> String? {
        guard let pid = item.projectID else { return nil }
        return store.projects.first(where: { $0.id == pid })?.name
    }

    var body: some View {
        List(filteredItems, selection: $selectedTask) { item in
            HStack {
                Button {
                    Task { await store.toggleItemCompletion(id: item.id) }
                } label: {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
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
                    HStack(spacing: 4) {
                        if let dueDate = item.dueDate {
                            Text(dueDate, style: .date)
                                .font(.caption)
                                .foregroundStyle(mode == .pastDue ? .red : .secondary)
                        }
                        if let name = projectName(for: item) {
                            Text("·")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(name)
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
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
        .navigationTitle(mode == .today ? "Todays ToDo" : "PastDue Do")
        .overlay {
            if filteredItems.isEmpty {
                ContentUnavailableView(
                    mode == .today ? "Nothing Due Today" : "No Overdue Tasks",
                    systemImage: mode == .today ? "sun.max.fill" : "checkmark.circle",
                    description: Text(mode == .today ? "You're all caught up!" : "No past-due tasks.")
                )
            }
        }
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
