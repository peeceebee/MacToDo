import Foundation

public struct Reminder: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var triggerDate: Date?
    public var relativeOffset: TimeInterval?

    public init(
        id: UUID = UUID(),
        triggerDate: Date? = nil,
        relativeOffset: TimeInterval? = nil
    ) {
        self.id = id
        self.triggerDate = triggerDate
        self.relativeOffset = relativeOffset
    }

    public func effectiveDate(relativeTo dueDate: Date?) -> Date? {
        if let triggerDate {
            return triggerDate
        }
        if let relativeOffset, let dueDate {
            return dueDate.addingTimeInterval(relativeOffset)
        }
        return nil
    }
}
