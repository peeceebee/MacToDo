import SwiftUI
import Models
import Storage
import ViewModels

struct ShoppingListView: View {
    @State private var viewModel: ShoppingListViewModel
    @State private var showingAddPanel = false
    @State private var itemName = ""
    @State private var itemQuantity = ""
    private let store: WorkspaceStore

    init(store: WorkspaceStore) {
        self.store = store
        _viewModel = State(initialValue: ShoppingListViewModel(store: store))
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header: "Shopping List" on left, "+" on right
            HStack {
                Text("Shopping List")
                    .font(.title2.weight(.semibold))
                Spacer()
                Button {
                    showingAddPanel.toggle()
                    if !showingAddPanel {
                        resetAddPanel()
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Add item")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Add panel (shown when + is pressed)
            if showingAddPanel {
                addPanel
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(.background.secondary)
                Divider()
            }

            // Shopping items list
            List {
                if !viewModel.activeItems.isEmpty {
                    Section("To Buy") {
                        ForEach(viewModel.activeItems) { item in
                            ShoppingRow(item: item, isPurchased: false) {
                                Task { await viewModel.togglePurchased(item) }
                            } onDelete: {
                                Task { await viewModel.deleteItem(item) }
                            }
                        }
                    }
                }

                if !viewModel.purchasedItems.isEmpty {
                    Section("Purchased") {
                        ForEach(viewModel.purchasedItems) { item in
                            ShoppingRow(item: item, isPurchased: true) {
                                Task { await viewModel.togglePurchased(item) }
                            } onDelete: {
                                Task { await viewModel.deleteItem(item) }
                            }
                        }
                    }
                }
            }
            .overlay {
                if viewModel.activeItems.isEmpty && viewModel.purchasedItems.isEmpty {
                    ContentUnavailableView(
                        "Shopping List Empty",
                        systemImage: "cart",
                        description: Text("Press + to add items.")
                    )
                }
            }
        }
    }

    @ViewBuilder
    private var addPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Line 1: Item name with autocomplete
            TextField("Item name", text: $itemName)
                .textFieldStyle(.roundedBorder)

            // Autocomplete suggestions
            let suggestions = viewModel.autocompleteSuggestions(for: itemName)
            if !suggestions.isEmpty {
                HStack(spacing: 6) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button {
                            itemName = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(.secondary.opacity(0.15))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Line 2: Quantity / description
            TextField("Quantity / description (optional)", text: $itemQuantity)
                .textFieldStyle(.roundedBorder)

            // Line 3: Add button
            Button("Add") {
                addItem()
            }
            .buttonStyle(.borderedProminent)
            .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private func addItem() {
        let name = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let qty = itemQuantity.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await viewModel.addItem(name: name, quantity: qty.isEmpty ? nil : qty)
        }
        resetAddPanel()
        showingAddPanel = false
    }

    private func resetAddPanel() {
        itemName = ""
        itemQuantity = ""
    }
}

// MARK: - Shopping Row

private struct ShoppingRow: View {
    let item: ShoppingItem
    let isPurchased: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack {
            Button(action: onToggle) {
                Image(systemName: isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isPurchased ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .strikethrough(isPurchased)
                    .foregroundStyle(isPurchased ? .secondary : .primary)
                if let qty = item.quantity {
                    Text(qty)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}
