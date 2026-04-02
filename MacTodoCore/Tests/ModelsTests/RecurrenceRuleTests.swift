import XCTest
import Foundation
@testable import Models

final class RecurrenceRuleTests: XCTestCase {
    let calendar = Calendar.current

    private func date(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        return calendar.date(from: components)!
    }

    func testDailyRecurrence() throws {
        let rule = RecurrenceRule(frequency: .daily, interval: 1)
        let start = date(year: 2026, month: 1, day: 15)
        let next = rule.nextOccurrence(after: start)!
        XCTAssertEqual(calendar.component(.day, from: next), 16)
    }

    func testDailyRecurrenceInterval3() throws {
        let rule = RecurrenceRule(frequency: .daily, interval: 3)
        let start = date(year: 2026, month: 1, day: 15)
        let next = rule.nextOccurrence(after: start)!
        XCTAssertEqual(calendar.component(.day, from: next), 18)
    }

    func testWeeklyRecurrence() throws {
        let rule = RecurrenceRule(frequency: .weekly, interval: 1)
        let start = date(year: 2026, month: 1, day: 15)
        let next = rule.nextOccurrence(after: start)!
        XCTAssertEqual(calendar.component(.day, from: next), 22)
    }

    func testMonthlyRecurrence() throws {
        let rule = RecurrenceRule(frequency: .monthly, interval: 1)
        let start = date(year: 2026, month: 1, day: 15)
        let next = rule.nextOccurrence(after: start)!
        XCTAssertEqual(calendar.component(.month, from: next), 2)
    }

    func testYearlyRecurrence() throws {
        let rule = RecurrenceRule(frequency: .yearly, interval: 1)
        let start = date(year: 2026, month: 3, day: 10)
        let next = rule.nextOccurrence(after: start)!
        XCTAssertEqual(calendar.component(.year, from: next), 2027)
    }

    func testRecurrenceWithEndDate() throws {
        let endDate = date(year: 2026, month: 1, day: 16)
        let rule = RecurrenceRule(frequency: .daily, interval: 1, endDate: endDate)
        let start = date(year: 2026, month: 1, day: 15)
        let next = rule.nextOccurrence(after: start)!
        XCTAssertEqual(calendar.component(.day, from: next), 16)

        let next2 = rule.nextOccurrence(after: next)
        XCTAssertNil(next2)
    }

    func testMonthlyWithDayOfMonth() throws {
        let rule = RecurrenceRule(frequency: .monthly, interval: 1, dayOfMonth: 28)
        let start = date(year: 2026, month: 1, day: 15)
        let next = rule.nextOccurrence(after: start)!
        XCTAssertEqual(calendar.component(.day, from: next), 28)
        XCTAssertEqual(calendar.component(.month, from: next), 1)
    }
}
