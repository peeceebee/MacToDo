import Foundation
import Models
import Storage

@MainActor
@Observable
public final class ShoppingListViewModel {
    private let store: WorkspaceStore

    public init(store: WorkspaceStore) {
        self.store = store
    }

    /// Items that are active (not deleted, not purchased)
    public var activeItems: [ShoppingItem] {
        store.shoppingItems.filter { !$0.isDeleted && !$0.isPurchased }
            .sorted { $0.createdAt > $1.createdAt }
    }

    /// Items that have been purchased (not deleted)
    public var purchasedItems: [ShoppingItem] {
        store.shoppingItems.filter { !$0.isDeleted && $0.isPurchased }
            .sorted { ($0.purchasedAt ?? $0.createdAt) > ($1.purchasedAt ?? $1.createdAt) }
    }

    /// Autocomplete suggestions from all historical items (including deleted/purchased)
    public func autocompleteSuggestions(for input: String) -> [String] {
        guard !input.isEmpty else { return [] }
        let lowered = input.lowercased()
        let allNames = Set(store.shoppingItems.map { $0.name.lowercased() })
        return allNames
            .filter { $0.hasPrefix(lowered) && $0 != lowered }
            .sorted()
            .prefix(5)
            .map { name in
                // Return the original-cased version from the most recent match
                store.shoppingItems
                    .last(where: { $0.name.lowercased() == name })?.name ?? name
            }
    }

    public func addItem(name: String, quantity: String?) async {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        let trimmedQty = quantity?.trimmingCharacters(in: .whitespacesAndNewlines)
        let item = ShoppingItem(
            name: trimmedName,
            quantity: (trimmedQty?.isEmpty ?? true) ? nil : trimmedQty
        )
        await store.addShoppingItem(item)
    }

    public func togglePurchased(_ item: ShoppingItem) async {
        await store.toggleShoppingItemPurchased(id: item.id)
    }

    public func deleteItem(_ item: ShoppingItem) async {
        await store.deleteShoppingItem(id: item.id)
    }
}
