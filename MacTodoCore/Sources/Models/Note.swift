import Foundation

public struct Note: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var title: String
    public var contents: String
    public var contactInfo: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        contents: String = "",
        contactInfo: String? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.contents = contents
        self.contactInfo = contactInfo
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
