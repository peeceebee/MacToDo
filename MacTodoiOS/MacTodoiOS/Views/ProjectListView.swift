import SwiftUI
import Models
import Storage
import ViewModels

struct ProjectListView: View {
    @State private var viewModel: ProjectListViewModel
    @State private var showingNewProject = false
    @State private var newProjectName = ""
    private let store: WorkspaceStore

    init(store: WorkspaceStore) {
        self.store = store
        _viewModel = State(initialValue: ProjectListViewModel(store: store))
    }

    var body: some View {
        List {
            ForEach(viewModel.projects) { project in
                NavigationLink(value: project) {
                    HStack {
                        Image(systemName: project.iconName)
                            .foregroundStyle(Color(hex: project.colorHex))
                        Text(project.name)
                        Spacer()
                        Text("\(viewModel.taskCount(for: project))")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .swipeActions(edge: .trailing) {
                    Button("Archive", role: .destructive) {
                        Task { await viewModel.archiveProject(project) }
                    }
                }
            }
        }
        .navigationTitle("ToDo Lists")
        .navigationDestination(for: Project.self) { project in
            TaskListView(project: project, store: store)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewProject = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New ToDo List", isPresented: $showingNewProject) {
            TextField("ToDo List name", text: $newProjectName)
            Button("Create") {
                guard !newProjectName.isEmpty else { return }
                Task {
                    await viewModel.createProject(name: newProjectName)
                    newProjectName = ""
                }
            }
            Button("Cancel", role: .cancel) { newProjectName = "" }
        }
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
