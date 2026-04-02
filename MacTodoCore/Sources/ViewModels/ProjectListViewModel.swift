import Foundation
import Models
import Storage

@MainActor
@Observable
public final class ProjectListViewModel {
    private let store: WorkspaceStore

    public init(store: WorkspaceStore) {
        self.store = store
    }

    public var projects: [Project] {
        store.projects.filter { !$0.isArchived }
    }

    public func taskCount(for project: Project) -> Int {
        store.items.filter { $0.projectID == project.id && !$0.isCompleted }.count
    }

    public func loadProjects() async {
        await store.load()
    }

    public func createProject(name: String, colorHex: String = "#007AFF", iconName: String = "folder.fill") async {
        let project = Project(name: name, colorHex: colorHex, iconName: iconName)
        await store.addProject(project)
    }

    public func archiveProject(_ project: Project) async {
        await store.archiveProject(id: project.id)
    }
}
