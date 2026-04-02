import SwiftUI
import Models
import Storage
import ViewModels

struct TaskDetailView: View {
    @State private var viewModel: TaskDetailViewModel
    @Environment(\.dismiss) private var dismiss

    init(item: TodoItem, store: WorkspaceStore) {
        _viewModel = State(initialValue: TaskDetailViewModel(item: item, store: store))
    }

    var body: some View {
        Form {
            Section("Details") {
                TextField("Title", text: $viewModel.item.title)

                TextField("Notes", text: $viewModel.item.notes, axis: .vertical)
                    .lineLimit(3...6)

                Picker("Priority", selection: $viewModel.item.priority) {
                    ForEach(Priority.allCases, id: \.self) { priority in
                        Text(priority.label).tag(priority)
                    }
                }

                DatePicker("Due Date", selection: Binding(
                    get: { viewModel.item.dueDate ?? Date() },
                    set: { viewModel.item.dueDate = $0 }
                ), displayedComponents: [.date, .hourAndMinute])

                Toggle("Has Due Date", isOn: Binding(
                    get: { viewModel.item.dueDate != nil },
                    set: { viewModel.item.dueDate = $0 ? Date() : nil }
                ))
            }

            Section("Project") {
                Picker("Project", selection: $viewModel.item.projectID) {
                    Text("None").tag(UUID?.none)
                    ForEach(viewModel.availableProjects) { project in
                        Label(project.name, systemImage: project.iconName)
                            .tag(Optional(project.id))
                    }
                }
            }

            Section("Recurrence") {
                if let rule = viewModel.item.recurrenceRule {
                    Text("Repeats \(rule.frequency.rawValue) (every \(rule.interval))")
                    Button("Remove Recurrence", role: .destructive) {
                        Task { await viewModel.setRecurrence(nil) }
                    }
                } else {
                    Button("Add Recurrence") {
                        Task {
                            await viewModel.setRecurrence(RecurrenceRule(frequency: .daily))
                        }
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
                    }
                }
                Button("Add Reminder") {
                    Task {
                        await viewModel.addReminder(Reminder(triggerDate: Date().addingTimeInterval(3600)))
                    }
                }
            }
        }
        .navigationTitle("Edit Task")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    Task {
                        await viewModel.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
