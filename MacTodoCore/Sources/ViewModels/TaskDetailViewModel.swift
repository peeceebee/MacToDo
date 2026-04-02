import Foundation
import Models
import Storage

@MainActor
@Observable
public final class TaskDetailViewModel {
    public var item: TodoItem
    public var availableProjects: [Project] { store.projects }
    public var availableTags: [Tag] { store.tags }

    private let store: WorkspaceStore

    public init(item: TodoItem, store: WorkspaceStore) {
        self.item = item
        self.store = store
    }

    public func save() async {
        await store.updateItem(item)
    }

    public func addSubtask(title: String) async {
        let subtask = TodoItem(
            title: title,
            parentTaskID: item.id,
            sortOrder: item.subtaskIDs.count
        )
        item.subtaskIDs.append(subtask.id)
        await store.addItem(subtask)
        await store.updateItem(item)
    }

    public func addReminder(_ reminder: Reminder) async {
        item.reminders.append(reminder)
        await save()
    }

    public func setRecurrence(_ rule: RecurrenceRule?) async {
        item.recurrenceRule = rule
        await save()
    }
}
