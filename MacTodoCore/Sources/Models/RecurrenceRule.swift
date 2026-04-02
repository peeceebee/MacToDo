import Foundation

public enum RecurrenceFrequency: String, Codable, Sendable, Hashable, CaseIterable {
    case daily
    case weekly
    case monthly
    case yearly
}

public struct RecurrenceRule: Codable, Sendable, Hashable {
    public var frequency: RecurrenceFrequency
    public var interval: Int
    public var daysOfWeek: [Int]?
    public var dayOfMonth: Int?
    public var endDate: Date?
    public var occurrenceCount: Int?

    public init(
        frequency: RecurrenceFrequency,
        interval: Int = 1,
        daysOfWeek: [Int]? = nil,
        dayOfMonth: Int? = nil,
        endDate: Date? = nil,
        occurrenceCount: Int? = nil
    ) {
        self.frequency = frequency
        self.interval = interval
        self.daysOfWeek = daysOfWeek
        self.dayOfMonth = dayOfMonth
        self.endDate = endDate
        self.occurrenceCount = occurrenceCount
    }

    public func nextOccurrence(after date: Date) -> Date? {
        let calendar = Calendar.current

        var candidate: Date?

        switch frequency {
        case .daily:
            candidate = calendar.date(byAdding: .day, value: interval, to: date)

        case .weekly:
            if let daysOfWeek, !daysOfWeek.isEmpty {
                let currentWeekday = calendar.component(.weekday, from: date)
                let sortedDays = daysOfWeek.sorted()

                if let nextDay = sortedDays.first(where: { $0 > currentWeekday }) {
                    let diff = nextDay - currentWeekday
                    candidate = calendar.date(byAdding: .day, value: diff, to: date)
                } else if let firstDay = sortedDays.first {
                    let diff = 7 * interval - currentWeekday + firstDay
                    candidate = calendar.date(byAdding: .day, value: diff, to: date)
                }
            } else {
                candidate = calendar.date(byAdding: .weekOfYear, value: interval, to: date)
            }

        case .monthly:
            if let dayOfMonth {
                var components = calendar.dateComponents([.year, .month], from: date)
                components.day = dayOfMonth
                if let proposed = calendar.date(from: components), proposed > date {
                    candidate = proposed
                } else {
                    let base = calendar.date(byAdding: .month, value: interval, to: date) ?? date
                    components = calendar.dateComponents([.year, .month], from: base)
                    components.day = min(dayOfMonth, calendar.range(of: .day, in: .month, for: base)?.count ?? 28)
                    candidate = calendar.date(from: components)
                }
            } else {
                candidate = calendar.date(byAdding: .month, value: interval, to: date)
            }

        case .yearly:
            candidate = calendar.date(byAdding: .year, value: interval, to: date)
        }

        if let endDate, let candidate, candidate > endDate {
            return nil
        }

        return candidate
    }
}
