import SwiftUI
import Models
import Storage
import ViewModels

struct SidebarView: View {
    @Binding var selectedItem: ContentView.SidebarItem?
    @State private var viewModel: ProjectListViewModel
    @State private var showingNewTodoList = false
    @State private var newTodoListName = ""

    init(selectedItem: Binding<ContentView.SidebarItem?>, store: WorkspaceStore) {
        _selectedItem = selectedItem
        _viewModel = State(initialValue: ProjectListViewModel(store: store))
    }

    var body: some View {
        List(selection: $selectedItem) {
            // Todays ToDo / PastDue Do (cycling)
            todayToggleRow

            // Shopping List
            Label("Shopping List", systemImage: "cart.fill")
                .tag(ContentView.SidebarItem.shoppingList)

            // Schedule
            Label("Schedule", systemImage: "calendar")
                .tag(ContentView.SidebarItem.schedule)

            // ToDo Lists
            Section("ToDo Lists") {
                ForEach(viewModel.projects) { project in
                    Label {
                        HStack {
                            Text(project.name)
                            Spacer()
                            Text("\(viewModel.taskCount(for: project))")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    } icon: {
                        Image(systemName: project.iconName)
                            .foregroundStyle(Color(hex: project.colorHex))
                    }
                    .tag(ContentView.SidebarItem.todoList(project))
                }
            }
        }
        .navigationTitle("MacTodo")
        .safeAreaInset(edge: .bottom) {
            Button {
                showingNewTodoList = true
            } label: {
                Label("Add ToDo List", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        .alert("New ToDo List", isPresented: $showingNewTodoList) {
            TextField("ToDo List name", text: $newTodoListName)
            Button("Create") {
                guard !newTodoListName.isEmpty else { return }
                Task {
                    await viewModel.createProject(name: newTodoListName)
                    newTodoListName = ""
                }
            }
            Button("Cancel", role: .cancel) { newTodoListName = "" }
        }
        .onReceive(NotificationCenter.default.publisher(for: .newProject)) { _ in
            showingNewTodoList = true
        }
    }

    @ViewBuilder
    private var todayToggleRow: some View {
        let isTodaySelected = selectedItem == .todaysTodo
        let isPastDueSelected = selectedItem == .pastDueDo

        Button {
            if isTodaySelected {
                selectedItem = .pastDueDo
            } else if isPastDueSelected {
                selectedItem = .todaysTodo
            } else {
                selectedItem = .todaysTodo
            }
        } label: {
            Label {
                Text(isTodaySelected || (!isTodaySelected && !isPastDueSelected) ? "Todays ToDo" : "PastDue Do")
            } icon: {
                Image(systemName: isPastDueSelected ? "exclamationmark.circle.fill" : "sun.max.fill")
                    .foregroundStyle(isPastDueSelected ? .red : .orange)
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(
            (isTodaySelected || isPastDueSelected) ? Color.accentColor.opacity(0.15) : Color.clear
        )
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
