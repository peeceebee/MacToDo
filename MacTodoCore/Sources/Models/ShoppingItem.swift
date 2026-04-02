import Foundation

public struct ShoppingItem: Codable, Sendable, Hashable, Identifiable {
    public var id: UUID
    public var name: String
    public var quantity: String?
    public var isPurchased: Bool
    public var createdAt: Date
    public var purchasedAt: Date?
    public var isDeleted: Bool

    public init(
        id: UUID = UUID(),
        name: String,
        quantity: String? = nil,
        isPurchased: Bool = false,
        createdAt: Date = Date(),
        purchasedAt: Date? = nil,
        isDeleted: Bool = false
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.isPurchased = isPurchased
        self.createdAt = createdAt
        self.purchasedAt = purchasedAt
        self.isDeleted = isDeleted
    }

    public mutating func togglePurchased() {
        isPurchased.toggle()
        purchasedAt = isPurchased ? Date() : nil
    }
}
