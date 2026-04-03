import Foundation

public struct TodoItem: Sendable, Hashable, Identifiable {
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
    /// Freeform assignee name or initials (e.g. "PB", "Peter", "Alice B.")
    public var assignee: String?
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
        assignee: String? = nil,
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
        self.assignee = assignee
        self.sortOrder = sortOrder
    }

    public mutating func toggleCompletion() {
        isCompleted.toggle()
        completedAt = isCompleted ? Date() : nil
        updatedAt = Date()
    }

    /// Returns "(XYZ) " prefix string for list display, or "" if no assignee.
    public var assigneePrefix: String {
        guard let name = assignee?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            return ""
        }
        let letters = String(name.prefix(3)).uppercased()
        return "(\(letters)) "
    }
}

// MARK: - Codable (backward compatible: old data used assigneeID: UUID?)
extension TodoItem: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, title, notes, isCompleted, completedAt, createdAt, updatedAt
        case dueDate, priority, recurrenceRule, tags, projectID, parentTaskID
        case subtaskIDs, reminders, assignee, sortOrder
        // legacy key — read but ignored
        case assigneeID
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self, forKey: .id)
        title          = try c.decode(String.self, forKey: .title)
        notes          = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        isCompleted    = try c.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        completedAt    = try c.decodeIfPresent(Date.self, forKey: .completedAt)
        createdAt      = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt      = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        dueDate        = try c.decodeIfPresent(Date.self, forKey: .dueDate)
        priority       = try c.decodeIfPresent(Priority.self, forKey: .priority) ?? .none
        recurrenceRule = try c.decodeIfPresent(RecurrenceRule.self, forKey: .recurrenceRule)
        tags           = try c.decodeIfPresent([UUID].self, forKey: .tags) ?? []
        projectID      = try c.decodeIfPresent(UUID.self, forKey: .projectID)
        parentTaskID   = try c.decodeIfPresent(UUID.self, forKey: .parentTaskID)
        subtaskIDs     = try c.decodeIfPresent([UUID].self, forKey: .subtaskIDs) ?? []
        reminders      = try c.decodeIfPresent([Reminder].self, forKey: .reminders) ?? []
        assignee       = try c.decodeIfPresent(String.self, forKey: .assignee)
        sortOrder      = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
        // assigneeID (legacy UUID) is decoded and discarded
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(title, forKey: .title)
        try c.encode(notes, forKey: .notes)
        try c.encode(isCompleted, forKey: .isCompleted)
        try c.encodeIfPresent(completedAt, forKey: .completedAt)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(dueDate, forKey: .dueDate)
        try c.encode(priority, forKey: .priority)
        try c.encodeIfPresent(recurrenceRule, forKey: .recurrenceRule)
        try c.encode(tags, forKey: .tags)
        try c.encodeIfPresent(projectID, forKey: .projectID)
        try c.encodeIfPresent(parentTaskID, forKey: .parentTaskID)
        try c.encode(subtaskIDs, forKey: .subtaskIDs)
        try c.encode(reminders, forKey: .reminders)
        try c.encodeIfPresent(assignee, forKey: .assignee)
        try c.encode(sortOrder, forKey: .sortOrder)
    }
}
