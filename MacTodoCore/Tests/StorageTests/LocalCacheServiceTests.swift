import XCTest
import Foundation
@testable import Models
@testable import Storage

final class LocalCacheServiceTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacTodoTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    private func makeService() -> LocalCacheService {
        LocalCacheService(baseDirectory: tempDir)
    }

    func testSaveAndLoad() async throws {
        let service = makeService()
        let ws = Workspace(items: [TodoItem(title: "Hello")])
        try await service.saveWorkspace(ws)

        let loaded = try await service.loadWorkspace(id: ws.id)
        XCTAssertEqual(loaded.id, ws.id)
        XCTAssertEqual(loaded.items.count, 1)
        XCTAssertEqual(loaded.items[0].title, "Hello")
    }

    func testListWorkspaces() async throws {
        let service = makeService()
        let ws1 = Workspace()
        let ws2 = Workspace()
        try await service.saveWorkspace(ws1)
        try await service.saveWorkspace(ws2)

        let ids = try await service.listWorkspaces()
        XCTAssertTrue(ids.contains(ws1.id))
        XCTAssertTrue(ids.contains(ws2.id))
    }

    func testDeleteWorkspace() async throws {
        let service = makeService()
        let ws = Workspace()
        try await service.saveWorkspace(ws)
        try await service.deleteWorkspace(id: ws.id)

        let ids = try await service.listWorkspaces()
        XCTAssertFalse(ids.contains(ws.id))
    }

    func testLoadNonexistent() async {
        let service = makeService()
        do {
            _ = try await service.loadWorkspace(id: UUID())
            XCTFail("Expected error")
        } catch is StorageError {
            // expected
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
}
