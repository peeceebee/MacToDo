import Foundation
import Models
import Storage

@MainActor
@Observable
public final class TaskDetailViewModel {
    public var item: TodoItem
    public var availableProjects: [Project]
    public var availableTags: [Tag]

    private let syncEngine: SyncEngine
    private let workspaceID: UUID
    private var workspace: Workspace?

    public init(item: TodoItem, workspace: Workspace, syncEngine: SyncEngine) {
        self.item = item
        self.availableProjects = workspace.projects
        self.availableTags = workspace.tags
        self.syncEngine = syncEngine
        self.workspaceID = workspace.id
        self.workspace = workspace
    }

    public func save() async {
        guard var ws = workspace else { return }
        if let index = ws.items.firstIndex(where: { $0.id == item.id }) {
            item.updatedAt = Date()
            ws.items[index] = item
        }
        self.workspace = ws
        await syncEngine.saveWorkspace(ws)
    }

    public func addSubtask(title: String) async {
        guard var ws = workspace else { return }
        let subtask = TodoItem(
            title: title,
            parentTaskID: item.id,
            sortOrder: item.subtaskIDs.count
        )
        item.subtaskIDs.append(subtask.id)
        ws.items.append(subtask)
        if let index = ws.items.firstIndex(where: { $0.id == item.id }) {
            ws.items[index] = item
        }
        self.workspace = ws
        await syncEngine.saveWorkspace(ws)
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
