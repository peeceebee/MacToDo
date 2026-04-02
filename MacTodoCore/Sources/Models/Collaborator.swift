import Foundation

public struct Collaborator: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var displayName: String
    public var email: String?
    public var avatarURL: URL?

    public init(
        id: UUID = UUID(),
        displayName: String,
        email: String? = nil,
        avatarURL: URL? = nil
    ) {
        self.id = id
        self.displayName = displayName
        self.email = email
        self.avatarURL = avatarURL
    }
}
