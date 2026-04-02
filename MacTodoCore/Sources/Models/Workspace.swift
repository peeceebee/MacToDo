import Foundation

public struct Workspace: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var lastModified: Date
    public var items: [TodoItem]
    public var projects: [Project]
    public var tags: [Tag]
    public var collaborators: [Collaborator]

    public init(
        id: UUID = UUID(),
        lastModified: Date = Date(),
        items: [TodoItem] = [],
        projects: [Project] = [],
        tags: [Tag] = [],
        collaborators: [Collaborator] = []
    ) {
        self.id = id
        self.lastModified = lastModified
        self.items = items
        self.projects = projects
        self.tags = tags
        self.collaborators = collaborators
    }

    public mutating func touch() {
        lastModified = Date()
    }
}
