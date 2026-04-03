import Foundation

public enum ScheduleEventType: String, Codable, Sendable, CaseIterable {
    case birthday    = "Birthday"
    case anniversary = "Anniversary"
    case other       = "Other"

    public var icon: String {
        switch self {
        case .birthday:    return "gift"
        case .anniversary: return "heart"
        case .other:       return "calendar"
        }
    }
}

public struct ScheduleEvent: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var title: String
    public var date: Date
    public var type: ScheduleEventType
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        date: Date = Date(),
        type: ScheduleEventType = .other,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.type = type
        self.createdAt = createdAt
    }
}
