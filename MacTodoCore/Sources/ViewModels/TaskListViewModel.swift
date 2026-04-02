import Foundation
import Models
import Storage
import SwiftUI

@MainActor
@Observable
public final class TaskListViewModel {
    public var items: [TodoItem] = []
    public var filterProject: Project?
    public var filterTag: Tag?
    public var showCompleted: Bool = false
    public var searchText: String = ""
    public var workspace: Workspace?

    public var filteredItems: [TodoItem] {
        items.filter { item in
            if !showCompleted && item.isCompleted { return false }
            if let filterProject, item.projectID != filterProject.id { return false }
            if let filterTag, !item.tags.contains(filterTag.id) { return false }
            if !searchText.isEmpty {
                let text = searchText.lowercased()
                if !item.title.lowercased().contains(text) && !item.notes.lowercased().contains(text) {
                    return false
                }
            }
            return true
        }
        .sorted { a, b in
            if a.isCompleted != b.isCompleted { return !a.isCompleted }
            if a.priority != b.priority { return a.priority > b.priority }
            return a.sortOrder < b.sortOrder
        }
    }

    private let syncEngine: SyncEngine
    private let workspaceID: UUID

    public init(syncEngine: SyncEngine, workspaceID: UUID) {
        self.syncEngine = syncEngine
        self.workspaceID = workspaceID
    }

    public func loadTasks() async {
        let ws = await syncEngine.loadWorkspace(id: workspaceID)
        self.workspace = ws
        self.items = ws.items
    }

    public func toggleCompletion(_ item: TodoItem) async {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].toggleCompletion()
        await saveAll()
    }

    public func deleteTask(_ item: TodoItem) async {
        items.removeAll { $0.id == item.id }
        await saveAll()
    }

    public func addTask(title: String, projectID: UUID? = nil) async {
        let task = TodoItem(
            title: title,
            projectID: projectID,
            sortOrder: items.count
        )
        items.append(task)
        await saveAll()
    }

    private func saveAll() async {
        guard var ws = workspace else { return }
        ws.items = items
        self.workspace = ws
        await syncEngine.saveWorkspace(ws)
    }
}
