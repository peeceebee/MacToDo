import XCTest
import Foundation
@testable import Models

final class CodableRoundTripTests: XCTestCase {
    let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = .sortedKeys
        return e
    }()

    let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    func testTodoItemRoundTrip() throws {
        let item = TodoItem(
            title: "Test task",
            notes: "Some notes",
            isCompleted: true,
            completedAt: Date(),
            dueDate: Date().addingTimeInterval(86400),
            priority: .high,
            recurrenceRule: RecurrenceRule(frequency: .weekly, interval: 2, daysOfWeek: [2, 4]),
            tags: [UUID()],
            projectID: UUID(),
            parentTaskID: UUID(),
            subtaskIDs: [UUID(), UUID()],
            reminders: [Reminder(triggerDate: Date())],
            assigneeID: UUID(),
            sortOrder: 5
        )
        let data = try encoder.encode(item)
        let decoded = try decoder.decode(TodoItem.self, from: data)
        XCTAssertEqual(decoded.id, item.id)
        XCTAssertEqual(decoded.title, item.title)
        XCTAssertEqual(decoded.notes, item.notes)
        XCTAssertEqual(decoded.isCompleted, item.isCompleted)
        XCTAssertEqual(decoded.priority, item.priority)
        XCTAssertEqual(decoded.tags, item.tags)
        XCTAssertEqual(decoded.subtaskIDs, item.subtaskIDs)
        XCTAssertEqual(decoded.sortOrder, item.sortOrder)
    }

    func testTodoItemMinimalRoundTrip() throws {
        let item = TodoItem(title: "Minimal")
        let data = try encoder.encode(item)
        let decoded = try decoder.decode(TodoItem.self, from: data)
        XCTAssertEqual(decoded.id, item.id)
        XCTAssertEqual(decoded.title, "Minimal")
        XCTAssertNil(decoded.dueDate)
        XCTAssertNil(decoded.recurrenceRule)
        XCTAssertNil(decoded.projectID)
    }

    func testProjectRoundTrip() throws {
        let project = Project(name: "Work", colorHex: "#FF0000", iconName: "briefcase.fill", itemIDs: [UUID()])
        let data = try encoder.encode(project)
        let decoded = try decoder.decode(Project.self, from: data)
        XCTAssertEqual(decoded.id, project.id)
        XCTAssertEqual(decoded.name, project.name)
        XCTAssertEqual(decoded.colorHex, project.colorHex)
    }

    func testTagRoundTrip() throws {
        let tag = Tag(name: "urgent", colorHex: "#FF0000")
        let data = try encoder.encode(tag)
        let decoded = try decoder.decode(Tag.self, from: data)
        XCTAssertEqual(decoded, tag)
    }

    func testCollaboratorRoundTrip() throws {
        let collab = Collaborator(displayName: "Alice", email: "alice@example.com")
        let data = try encoder.encode(collab)
        let decoded = try decoder.decode(Collaborator.self, from: data)
        XCTAssertEqual(decoded.displayName, "Alice")
        XCTAssertEqual(decoded.email, "alice@example.com")
    }

    func testWorkspaceRoundTrip() throws {
        let ws = Workspace(
            items: [TodoItem(title: "Task 1")],
            projects: [Project(name: "Proj")],
            tags: [Tag(name: "tag1")],
            collaborators: [Collaborator(displayName: "Bob")]
        )
        let data = try encoder.encode(ws)
        let decoded = try decoder.decode(Workspace.self, from: data)
        XCTAssertEqual(decoded.id, ws.id)
        XCTAssertEqual(decoded.items.count, 1)
        XCTAssertEqual(decoded.projects.count, 1)
        XCTAssertEqual(decoded.tags.count, 1)
        XCTAssertEqual(decoded.collaborators.count, 1)
    }

    func testReminderWithAbsoluteDate() throws {
        let reminder = Reminder(triggerDate: Date())
        let data = try encoder.encode(reminder)
        let decoded = try decoder.decode(Reminder.self, from: data)
        XCTAssertEqual(decoded.id, reminder.id)
        XCTAssertNotNil(decoded.triggerDate)
        XCTAssertNil(decoded.relativeOffset)
    }

    func testReminderWithRelativeOffset() throws {
        let reminder = Reminder(relativeOffset: -3600)
        let data = try encoder.encode(reminder)
        let decoded = try decoder.decode(Reminder.self, from: data)
        XCTAssertEqual(decoded.relativeOffset, -3600)
        XCTAssertNil(decoded.triggerDate)
    }
}
