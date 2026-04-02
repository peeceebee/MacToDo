import SwiftUI
import Models
import Storage
import ViewModels

struct SidebarView: View {
    @Binding var selectedItem: ContentView.SidebarItem?
    @State private var viewModel: ProjectListViewModel
    @State private var showingNewProject = false
    @State private var newProjectName = ""

    init(selectedItem: Binding<ContentView.SidebarItem?>, syncEngine: SyncEngine, workspaceID: UUID) {
        _selectedItem = selectedItem
        _viewModel = State(initialValue: ProjectListViewModel(syncEngine: syncEngine, workspaceID: workspaceID))
    }

    var body: some View {
        List(selection: $selectedItem) {
            Section("Smart Filters") {
                Label("All Tasks", systemImage: "tray.full")
                    .tag(ContentView.SidebarItem.allTasks)

                Label("Today", systemImage: "calendar")
                    .tag(ContentView.SidebarItem.today)

                Label("Upcoming", systemImage: "calendar.badge.clock")
                    .tag(ContentView.SidebarItem.upcoming)
            }

            Section("Projects") {
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
                    .tag(ContentView.SidebarItem.project(project))
                }
            }
        }
        .navigationTitle("MacTodo")
        .safeAreaInset(edge: .bottom) {
            Button {
                showingNewProject = true
            } label: {
                Label("Add Project", systemImage: "plus.circle")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
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
        .onReceive(NotificationCenter.default.publisher(for: .newProject)) { _ in
            showingNewProject = true
        }
    }
}

// Reuse the hex Color init
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
