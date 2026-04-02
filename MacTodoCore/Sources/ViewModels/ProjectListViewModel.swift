import Foundation
import Models
import Storage

@MainActor
@Observable
public final class ProjectListViewModel {
    public var projects: [Project] = []
    public var allItems: [TodoItem] = []

    private let syncEngine: SyncEngine
    private let workspaceID: UUID
    private var workspace: Workspace?

    public init(syncEngine: SyncEngine, workspaceID: UUID) {
        self.syncEngine = syncEngine
        self.workspaceID = workspaceID
    }

    public func loadProjects() async {
        let ws = await syncEngine.loadWorkspace(id: workspaceID)
        self.workspace = ws
        self.projects = ws.projects.filter { !$0.isArchived }
        self.allItems = ws.items
    }

    public func taskCount(for project: Project) -> Int {
        allItems.filter { $0.projectID == project.id && !$0.isCompleted }.count
    }

    public func createProject(name: String, colorHex: String = "#007AFF", iconName: String = "folder.fill") async {
        let project = Project(name: name, colorHex: colorHex, iconName: iconName)
        projects.append(project)
        await saveAll()
    }

    public func archiveProject(_ project: Project) async {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projects[index].isArchived = true
        projects[index].updatedAt = Date()
        await saveAll()
        projects.removeAll { $0.id == project.id }
    }

    private func saveAll() async {
        guard var ws = workspace else { return }
        ws.projects = projects
        self.workspace = ws
        await syncEngine.saveWorkspace(ws)
    }
}
