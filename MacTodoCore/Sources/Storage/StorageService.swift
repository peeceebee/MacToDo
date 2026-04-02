import Foundation
import Models

public protocol StorageService: Sendable {
    func loadWorkspace(id: UUID) async throws -> Workspace
    func saveWorkspace(_ workspace: Workspace) async throws
    func listWorkspaces() async throws -> [UUID]
    func deleteWorkspace(id: UUID) async throws
}

public enum StorageError: Error, Sendable {
    case workspaceNotFound(UUID)
    case networkError(String)
    case encodingError(String)
    case decodingError(String)
    case authenticationError(String)
    case unexpectedResponse(Int)
}
