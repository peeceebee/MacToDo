import SwiftUI
import Models
import Storage
import ViewModels

struct ProjectListView: View {
    @State private var viewModel: ProjectListViewModel
    @State private var showingNewProject = false
    @State private var newProjectName = ""

    init(syncEngine: SyncEngine, workspaceID: UUID) {
        _viewModel = State(initialValue: ProjectListViewModel(syncEngine: syncEngine, workspaceID: workspaceID))
    }

    var body: some View {
        List {
            ForEach(viewModel.projects) { project in
                HStack {
                    Image(systemName: project.iconName)
                        .foregroundStyle(Color(hex: project.colorHex))
                    Text(project.name)
                    Spacer()
                    Text("\(viewModel.taskCount(for: project))")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .swipeActions(edge: .trailing) {
                    Button("Archive", role: .destructive) {
                        Task { await viewModel.archiveProject(project) }
                    }
                }
            }
        }
        .navigationTitle("Projects")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewProject = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .alert("New Project", isPresented: $showingNewProject) {
            TextField("Project name", text: $newProjectName)
            Button("Create") {
                guard !newProjectName.isEmpty else { return }
                Task {
                    await viewModel.createProject(name: newProjectName)
                    newProjectName = ""
                }
            }
            Button("Cancel", role: .cancel) { newProjectName = "" }
        }
        .task {
            await viewModel.loadProjects()
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
