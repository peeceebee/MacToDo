import Foundation

public struct Project: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var colorHex: String
    public var iconName: String
    public var itemIDs: [UUID]
    public var createdAt: Date
    public var updatedAt: Date
    public var isArchived: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#007AFF",
        iconName: String = "folder.fill",
        itemIDs: [UUID] = [],
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isArchived: Bool = false
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.iconName = iconName
        self.itemIDs = itemIDs
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
    }
}
