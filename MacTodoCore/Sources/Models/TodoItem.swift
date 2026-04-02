import Foundation

public struct TodoItem: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var title: String
    public var notes: String
    public var isCompleted: Bool
    public var completedAt: Date?
    public var createdAt: Date
    public var updatedAt: Date
    public var dueDate: Date?
    public var priority: Priority
    public var recurrenceRule: RecurrenceRule?
    public var tags: [UUID]
    public var projectID: UUID?
    public var parentTaskID: UUID?
    public var subtaskIDs: [UUID]
    public var reminders: [Reminder]
    public var assigneeID: UUID?
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        isCompleted: Bool = false,
        completedAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        dueDate: Date? = nil,
        priority: Priority = .none,
        recurrenceRule: RecurrenceRule? = nil,
        tags: [UUID] = [],
        projectID: UUID? = nil,
        parentTaskID: UUID? = nil,
        subtaskIDs: [UUID] = [],
        reminders: [Reminder] = [],
        assigneeID: UUID? = nil,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.isCompleted = isCompleted
        self.completedAt = completedAt
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.dueDate = dueDate
        self.priority = priority
        self.recurrenceRule = recurrenceRule
        self.tags = tags
        self.projectID = projectID
        self.parentTaskID = parentTaskID
        self.subtaskIDs = subtaskIDs
        self.reminders = reminders
        self.assigneeID = assigneeID
        self.sortOrder = sortOrder
    }

    public mutating func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
        updatedAt = Date()
    }
}
