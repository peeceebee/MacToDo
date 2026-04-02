import XCTest
import Foundation
@testable import Models
@testable import Storage

final class SyncEngineTests: XCTestCase {
    var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MacTodoSyncTests-\(UUID().uuidString)", isDirectory: true)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDir)
        super.tearDown()
    }

    func testLoadFromRemote() async throws {
        let remote = MockStorageService()
        let local = LocalCacheService(baseDirectory: tempDir)
        let engine = SyncEngine(remote: remote, local: local)

        let ws = Workspace(items: [TodoItem(title: "From remote")])
        try await remote.saveWorkspace(ws)

        let loaded = await engine.loadWorkspace(id: ws.id)
        XCTAssertEqual(loaded.items[0].title, "From remote")
    }

    func testSaveWritesLocalAndRemote() async throws {
        let remote = MockStorageService()
        let local = LocalCacheService(baseDirectory: tempDir)
        let engine = SyncEngine(remote: remote, local: local)

        let ws = Workspace(items: [TodoItem(title: "Saved")])
        await engine.saveWorkspace(ws)

        let remoteLoaded = try await remote.loadWorkspace(id: ws.id)
        XCTAssertEqual(remoteLoaded.items[0].title, "Saved")

        let localLoaded = try await local.loadWorkspace(id: ws.id)
        XCTAssertEqual(localLoaded.items[0].title, "Saved")
    }

    func testSyncLocalNewerWins() async throws {
        let remote = MockStorageService()
        let local = LocalCacheService(baseDirectory: tempDir)
        let engine = SyncEngine(remote: remote, local: local)

        let wsID = UUID()
        let oldDate = Date().addingTimeInterval(-3600)
        let remoteWS = Workspace(id: wsID, lastModified: oldDate, items: [TodoItem(title: "Old")])
        try await remote.saveWorkspace(remoteWS)

        let localWS = Workspace(id: wsID, lastModified: Date(), items: [TodoItem(title: "New")])
        try await local.saveWorkspace(localWS)

        await engine.sync(workspaceID: wsID)

        let afterSync = try await remote.loadWorkspace(id: wsID)
        XCTAssertEqual(afterSync.items[0].title, "New")
    }
}
