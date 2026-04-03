import Foundation

public struct Workspace: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var lastModified: Date
    public var items: [TodoItem]
    public var projects: [Project]
    public var tags: [Tag]
    public var collaborators: [Collaborator]
    public var shoppingItems: [ShoppingItem]
    public var scheduleEvents: [ScheduleEvent]

    public init(
        id: UUID = UUID(),
        lastModified: Date = Date(),
        items: [TodoItem] = [],
        projects: [Project] = [],
        tags: [Tag] = [],
        collaborators: [Collaborator] = [],
        shoppingItems: [ShoppingItem] = [],
        scheduleEvents: [ScheduleEvent] = []
    ) {
        self.id = id
        self.lastModified = lastModified
        self.items = items
        self.projects = projects
        self.tags = tags
        self.collaborators = collaborators
        self.shoppingItems = shoppingItems
        self.scheduleEvents = scheduleEvents
    }

    // Custom decoder for backward compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id             = try container.decode(UUID.self, forKey: .id)
        lastModified   = try container.decode(Date.self, forKey: .lastModified)
        items          = try container.decode([TodoItem].self, forKey: .items)
        projects       = try container.decode([Project].self, forKey: .projects)
        tags           = try container.decode([Tag].self, forKey: .tags)
        collaborators  = try container.decode([Collaborator].self, forKey: .collaborators)
        shoppingItems  = try container.decodeIfPresent([ShoppingItem].self, forKey: .shoppingItems) ?? []
        scheduleEvents = try container.decodeIfPresent([ScheduleEvent].self, forKey: .scheduleEvents) ?? []
    }

    public mutating func touch() {
        lastModified = Date()
    }
}
