import SwiftUI
import Models
import Storage
import ViewModels

struct ShoppingListiOSView: View {
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
        List {
            // Add panel (shown when + is pressed)
            if showingAddPanel {
                Section {
                    TextField("Item name", text: $itemName)

                    // Autocomplete suggestions
                    let suggestions = viewModel.autocompleteSuggestions(for: itemName)
                    if !suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button {
                                        itemName = suggestion
                                    } label: {
                                        Text(suggestion)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(.secondary.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    TextField("Quantity / description (optional)", text: $itemQuantity)

                    Button("Add") {
                        addItem()
                    }
                    .disabled(itemName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // Active items
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

            // Purchased items
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
        .navigationTitle("Shopping List")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddPanel.toggle()
                    if !showingAddPanel {
                        resetAddPanel()
                    }
                } label: {
                    Image(systemName: showingAddPanel ? "xmark" : "plus")
                }
            }
        }
        .overlay {
            if viewModel.activeItems.isEmpty && viewModel.purchasedItems.isEmpty && !showingAddPanel {
                ContentUnavailableView(
                    "Shopping List Empty",
                    systemImage: "cart",
                    description: Text("Press + to add items.")
                )
            }
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

            VStack(alignment: .leading) {
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
