import SwiftUI
import Models
import Storage
import ViewModels

struct TaskDetailMacView: View {
    @State private var item: TodoItem
    @State private var workspace: Workspace?
    private let syncEngine: SyncEngine
    private let workspaceID: UUID

    init(item: TodoItem, syncEngine: SyncEngine, workspaceID: UUID) {
        _item = State(initialValue: item)
        self.syncEngine = syncEngine
        self.workspaceID = workspaceID
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $item.title)
                    .textFieldStyle(.roundedBorder)

                TextField("Notes", text: $item.notes, axis: .vertical)
                    .lineLimit(3...10)

                Picker("Priority", selection: $item.priority) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }

                Toggle("Completed", isOn: $item.isCompleted)

                DatePicker("Due Date", selection: Binding(
                    get: { item.dueDate ?? Date() },
                    set: { item.dueDate = $0 }
                ), displayedComponents: [.date, .hourAndMinute])

                Toggle("Has Due Date", isOn: Binding(
                    get: { item.dueDate != nil },
                    set: { item.dueDate = $0 ? Date() : nil }
                ))
            }

            Section("Recurrence") {
                if let rule = item.recurrenceRule {
                    LabeledContent("Pattern", value: "\(rule.frequency.rawValue) (every \(rule.interval))")
                    Button("Remove Recurrence", role: .destructive) {
                        item.recurrenceRule = nil
                    }
                } else {
                    Button("Add Daily Recurrence") {
                        item.recurrenceRule = RecurrenceRule(frequency: .daily)
                    }
                }
            }

            Section("Reminders (\(item.reminders.count))") {
                ForEach(item.reminders) { reminder in
                    if let date = reminder.effectiveDate(relativeTo: item.dueDate) {
                        Text(date, style: .date)
                    }
                }
                Button("Add Reminder (+1 hour)") {
                    item.reminders.append(Reminder(triggerDate: Date().addingTimeInterval(3600)))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .toolbar {
            ToolbarItem {
                Button("Save") {
                    Task { await save() }
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
        .task {
            workspace = await syncEngine.loadWorkspace(id: workspaceID)
        }
    }

    private func save() async {
        guard var ws = workspace else { return }
        item.updatedAt = Date()
        if let index = ws.items.firstIndex(where: { $0.id == item.id }) {
            ws.items[index] = item
        }
        workspace = ws
        await syncEngine.saveWorkspace(ws)
    }
}
