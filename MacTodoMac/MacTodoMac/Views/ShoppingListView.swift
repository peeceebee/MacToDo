import SwiftUI
import Models
import Storage
import ViewModels

struct ShoppingListView: View {
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
        VStack(spacing: 0) {
            // Input bar
            inputBar
                .padding()

            Divider()

            // Badges
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !viewModel.activeItems.isEmpty {
                        Text("To Buy")
                            .font(.headline)
                            .padding(.horizontal)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                            ForEach(viewModel.activeItems) { item in
                                ShoppingBadge(item: item, isPurchased: false) {
                                    Task { await viewModel.togglePurchased(item) }
                                } onDelete: {
                                    Task { await viewModel.deleteItem(item) }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    if !viewModel.purchasedItems.isEmpty {
                        Text("Purchased")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                            ForEach(viewModel.purchasedItems) { item in
                                ShoppingBadge(item: item, isPurchased: true) {
                                    Task { await viewModel.togglePurchased(item) }
                                } onDelete: {
                                    Task { await viewModel.deleteItem(item) }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    if viewModel.activeItems.isEmpty && viewModel.purchasedItems.isEmpty {
                        ContentUnavailableView(
                            "Shopping List Empty",
                            systemImage: "cart",
                            description: Text("Add items above to get started.")
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationTitle("Shopping List")
    }

    @ViewBuilder
    private var inputBar: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if isEnteringQuantity {
                    Text(pendingName)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.blue.opacity(0.1))
                        .clipShape(Capsule())

                    TextField("Quantity (optional, e.g. 3 cans)", text: $quantityText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { addItem() }

                    Button("Add") { addItem() }
                        .buttonStyle(.borderedProminent)

                    Button("Cancel") {
                        isEnteringQuantity = false
                        pendingName = ""
                        quantityText = ""
                    }
                    .buttonStyle(.bordered)
                } else {
                    TextField("Add item...", text: $inputText)
                        .textFieldStyle(.roundedBorder)
                        .onSubmit { confirmName() }

                    Button("Add") { confirmName() }
                        .buttonStyle(.borderedProminent)
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }

            // Autocomplete suggestions
            if !isEnteringQuantity && !suggestions.isEmpty {
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

// MARK: - Shopping Badge

private struct ShoppingBadge: View {
    let item: ShoppingItem
    let isPurchased: Bool
    let onToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Button(action: onToggle) {
                Image(systemName: isPurchased ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isPurchased ? .green : .secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.callout)
                    .fontWeight(.medium)
                    .strikethrough(isPurchased)
                    .foregroundStyle(isPurchased ? .secondary : .primary)

                if let qty = item.quantity {
                    Text(qty)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary.opacity(0.6))
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(isPurchased ? Color.green.opacity(0.08) : Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
