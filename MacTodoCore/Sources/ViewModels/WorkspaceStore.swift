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
}
