import Foundation
import Models
import Storage

/// Single source of truth for workspace data, shared across all ViewModels.
/// Prevents stale-snapshot overwrites when multiple tabs save independently.
@MainActor
@Observable
public final class WorkspaceStore {
    public private(set) var workspace: Workspace
    public let workspaceID: UUID

    private let syncEngine: SyncEngine

    public init(syncEngine: SyncEngine, workspaceID: UUID) {
        self.syncEngine = syncEngine
        self.workspaceID = workspaceID
        self.workspace = Workspace(id: workspaceID)
    }

    public func load() async {
        workspace = await syncEngine.loadWorkspace(id: workspaceID)
    }

    public func save() async {
        workspace.touch()
        await syncEngine.saveWorkspace(workspace)
    }

    public func sync() async {
        await syncEngine.sync(workspaceID: workspaceID)
        await load()
    }

    public var syncStatus: SyncStatus {
        get async { await syncEngine.syncStatus }
    }

    // MARK: - Items

    public var items: [TodoItem] {
        get { workspace.items }
        set { workspace.items = newValue }
    }

    public func addItem(_ item: TodoItem) async {
        workspace.items.append(item)
        await save()
    }

    public func updateItem(_ item: TodoItem) async {
        if let index = workspace.items.firstIndex(where: { $0.id == item.id }) {
            var updated = item
            updated.updatedAt = Date()
            workspace.items[index] = updated
            await save()
        }
    }

    public func deleteItem(id: UUID) async {
        workspace.items.removeAll { $0.id == id }
        await save()
    }

    public func toggleItemCompletion(id: UUID) async {
        if let index = workspace.items.firstIndex(where: { $0.id == id }) {
            workspace.items[index].toggleCompletion()
            await save()
        }
    }

    // MARK: - Projects

    public var projects: [Project] {
        get { workspace.projects }
        set { workspace.projects = newValue }
    }

    public func addProject(_ project: Project) async {
        workspace.projects.append(project)
        await save()
    }

    public func updateProject(_ project: Project) async {
        if let index = workspace.projects.firstIndex(where: { $0.id == project.id }) {
            var updated = project
            updated.updatedAt = Date()
            workspace.projects[index] = updated
            await save()
        }
    }

    public func archiveProject(id: UUID) async {
        if let index = workspace.projects.firstIndex(where: { $0.id == id }) {
            workspace.projects[index].isArchived = true
            workspace.projects[index].updatedAt = Date()
            await save()
        }
    }

    // MARK: - Tags

    public var tags: [Tag] {
        get { workspace.tags }
        set { workspace.tags = newValue }
    }

    // MARK: - Collaborators

    public var collaborators: [Collaborator] {
        get { workspace.collaborators }
        set { workspace.collaborators = newValue }
    }

    // MARK: - Shopping Items

    public var shoppingItems: [ShoppingItem] {
        get { workspace.shoppingItems }
        set { workspace.shoppingItems = newValue }
    }

    public func addShoppingItem(_ item: ShoppingItem) async {
        workspace.shoppingItems.append(item)
        await save()
    }

    public func updateShoppingItem(_ item: ShoppingItem) async {
        if let index = workspace.shoppingItems.firstIndex(where: { $0.id == item.id }) {
            workspace.shoppingItems[index] = item
            await save()
        }
    }

    public func deleteShoppingItem(id: UUID) async {
        if let index = workspace.shoppingItems.firstIndex(where: { $0.id == id }) {
            workspace.shoppingItems[index].isDeleted = true
            await save()
        }
    }

    public func toggleShoppingItemPurchased(id: UUID) async {
        if let index = workspace.shoppingItems.firstIndex(where: { $0.id == id }) {
            workspace.shoppingItems[index].togglePurchased()
            await save()
        }
    }

    // MARK: - Schedule Events

    public var scheduleEvents: [ScheduleEvent] {
        get { workspace.scheduleEvents }
        set { workspace.scheduleEvents = newValue }
    }

    public func addScheduleEvent(_ event: ScheduleEvent) async {
        workspace.scheduleEvents.append(event)
        await save()
    }

    public func deleteScheduleEvent(id: UUID) async {
        workspace.scheduleEvents.removeAll { $0.id == id }
        await save()
    }

    // MARK: - Notes

    public var notes: [Note] {
        get { workspace.notes }
        set { workspace.notes = newValue }
    }

    public func addNote(_ note: Note) async {
        workspace.notes.append(note)
        await save()
    }

    public func updateNote(_ note: Note) async {
        if let index = workspace.notes.firstIndex(where: { $0.id == note.id }) {
            var updated = note
            updated.updatedAt = Date()
            workspace.notes[index] = updated
            await save()
        }
    }

    public func deleteNote(id: UUID) async {
        workspace.notes.removeAll { $0.id == id }
        await save()
    }
}
