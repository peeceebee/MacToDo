import SwiftUI
import Models
import Storage
import ViewModels

struct ShoppingListiOSView: View {
    @State private var viewModel: ShoppingListViewModel
    @State private var inputText = ""
    @State private var quantityText = ""
    @State private var pendingName = ""
    @State private var isEnteringQuantity = false

    init(store: WorkspaceStore) {
        _viewModel = State(initialValue: ShoppingListViewModel(store: store))
    }

    private var suggestions: [String] {
        viewModel.autocompleteSuggestions(for: inputText)
    }

    var body: some View {
        List {
            // Input section
            Section {
                if isEnteringQuantity {
                    HStack {
                        Text(pendingName)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.blue.opacity(0.1))
                            .clipShape(Capsule())
                        Spacer()
                    }
                    TextField("Quantity (optional, e.g. 3 cans)", text: $quantityText)
                        .onSubmit { addItem() }
                    HStack {
                        Button("Add") { addItem() }
                            .buttonStyle(.borderedProminent)
                        Button("Cancel") {
                            isEnteringQuantity = false
                            pendingName = ""
                            quantityText = ""
                        }
                    }
                } else {
                    TextField("Add item...", text: $inputText)
                        .onSubmit { confirmName() }

                    if !suggestions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(suggestions, id: \.self) { suggestion in
                                    Button {
                                        inputText = suggestion
                                        confirmName()
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
        .overlay {
            if viewModel.activeItems.isEmpty && viewModel.purchasedItems.isEmpty && !isEnteringQuantity {
                ContentUnavailableView(
                    "Shopping List Empty",
                    systemImage: "cart",
                    description: Text("Add items above to get started.")
                )
            }
        }
    }

    private func confirmName() {
        let name = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        pendingName = name
        inputText = ""
        isEnteringQuantity = true
    }

    private func addItem() {
        let qty = quantityText.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            await viewModel.addItem(name: pendingName, quantity: qty.isEmpty ? nil : qty)
        }
        pendingName = ""
        quantityText = ""
        isEnteringQuantity = false
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
