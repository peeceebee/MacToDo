import Foundation
import Models
import Storage
import SwiftUI

@MainActor
@Observable
public final class TaskListViewModel {
    public var filterProject: Project?
    public var filterTag: Tag?
    public var showCompleted: Bool = false
    public var searchText: String = ""

    private let store: WorkspaceStore

    public init(store: WorkspaceStore) {
        self.store = store
    }

    public var workspace: Workspace { store.workspace }

    public var filteredItems: [TodoItem] {
        store.items.filter { item in
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

    public func loadTasks() async {
        await store.load()
    }

    public func toggleCompletion(_ item: TodoItem) async {
        await store.toggleItemCompletion(id: item.id)
    }

    public func deleteTask(_ item: TodoItem) async {
        await store.deleteItem(id: item.id)
    }

    public func addTask(title: String, projectID: UUID? = nil) async {
        let task = TodoItem(
            title: title,
            projectID: projectID,
            sortOrder: store.items.count
        )
        await store.addItem(task)
    }
}
