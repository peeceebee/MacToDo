import XCTest
import Foundation
@testable import Models

final class TodoItemTests: XCTestCase {
    func testToggleCompletion() {
        var item = TodoItem(title: "Test")
        XCTAssertFalse(item.isCompleted)
        XCTAssertNil(item.completedAt)

        item.toggleCompletion()
        XCTAssertTrue(item.isCompleted)
        XCTAssertNotNil(item.completedAt)

        item.toggleCompletion()
        XCTAssertFalse(item.isCompleted)
        XCTAssertNil(item.completedAt)
    }

    func testDefaultValues() {
        let item = TodoItem(title: "Default test")
        XCTAssertEqual(item.title, "Default test")
        XCTAssertEqual(item.notes, "")
        XCTAssertFalse(item.isCompleted)
        XCTAssertEqual(item.priority, .none)
        XCTAssertTrue(item.tags.isEmpty)
        XCTAssertTrue(item.subtaskIDs.isEmpty)
        XCTAssertTrue(item.reminders.isEmpty)
        XCTAssertNil(item.projectID)
        XCTAssertNil(item.parentTaskID)
        XCTAssertNil(item.assigneeID)
    }

    func testPriorityComparable() {
        XCTAssertLessThan(Priority.none, Priority.low)
        XCTAssertLessThan(Priority.low, Priority.medium)
        XCTAssertLessThan(Priority.medium, Priority.high)
        XCTAssertLessThan(Priority.high, Priority.urgent)
    }

    func testReminderEffectiveDate() {
        let absoluteReminder = Reminder(triggerDate: Date())
        XCTAssertNotNil(absoluteReminder.effectiveDate(relativeTo: nil))

        let dueDate = Date().addingTimeInterval(7200)
        let relativeReminder = Reminder(relativeOffset: -3600)
        let effective = relativeReminder.effectiveDate(relativeTo: dueDate)
        XCTAssertNotNil(effective)

        let noDateReminder = Reminder(relativeOffset: -3600)
        XCTAssertNil(noDateReminder.effectiveDate(relativeTo: nil))
    }
}
