import SwiftUI
import Models
import Storage
import ViewModels

struct TaskDetailMacView: View {
    @State private var viewModel: TaskDetailViewModel

    init(item: TodoItem, store: WorkspaceStore) {
        _viewModel = State(initialValue: TaskDetailViewModel(item: item, store: store))
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $viewModel.item.title)
                    .textFieldStyle(.roundedBorder)

                TextField("Notes", text: $viewModel.item.notes, axis: .vertical)
                    .lineLimit(3...10)

                Picker("Priority", selection: $viewModel.item.priority) {
                    ForEach(Priority.allCases, id: \.self) { p in
                        Text(p.label).tag(p)
                    }
                }

                Toggle("Completed", isOn: $viewModel.item.isCompleted)

                DatePicker("Due Date", selection: Binding(
                    get: { viewModel.item.dueDate ?? Date() },
                    set: { viewModel.item.dueDate = $0 }
                ), displayedComponents: [.date, .hourAndMinute])

                Toggle("Has Due Date", isOn: Binding(
                    get: { viewModel.item.dueDate != nil },
                    set: { viewModel.item.dueDate = $0 ? Date() : nil }
                ))

                TextField("Assignee", text: Binding(
                    get: { viewModel.item.assignee ?? "" },
                    set: { viewModel.item.assignee = $0.isEmpty ? nil : $0 }
                ))
                .textFieldStyle(.roundedBorder)
                .help("Enter initials (PB), two initials (AB), or a name. Shows as (XYZ) in task lists.")
            }

            Section("Recurrence") {
                if let rule = viewModel.item.recurrenceRule {
                    LabeledContent("Pattern", value: "\(rule.frequency.rawValue) (every \(rule.interval))")
                    Button("Remove Recurrence", role: .destructive) {
                        viewModel.item.recurrenceRule = nil
                    }
                } else {
                    Button("Add Daily Recurrence") {
                        viewModel.item.recurrenceRule = RecurrenceRule(frequency: .daily)
                    }
                }
            }

            Section("Reminders (\(viewModel.item.reminders.count))") {
                ForEach(viewModel.item.reminders) { reminder in
                    HStack {
                        if let date = reminder.effectiveDate(relativeTo: viewModel.item.dueDate) {
                            Text(date, style: .date)
                        } else {
                            Text("Reminder")
                        }
                        Spacer()
                        Button {
                            viewModel.item.reminders.removeAll { $0.id == reminder.id }
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .help("Remove reminder")
                    }
                }
                Button("Add Reminder (+1 hour)") {
                    viewModel.item.reminders.append(Reminder(triggerDate: Date().addingTimeInterval(3600)))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .toolbar {
            ToolbarItem {
                Button("Save") {
                    Task { await viewModel.save() }
                }
                .keyboardShortcut("s", modifiers: .command)
            }
        }
    }
}
