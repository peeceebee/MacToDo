import SwiftUI
import Storage
import ViewModels

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(syncEngine: SyncEngine, workspaceID: UUID, localCache: LocalCacheService) {
        _viewModel = State(initialValue: SettingsViewModel(syncEngine: syncEngine, workspaceID: workspaceID, localCache: localCache))
    }

    var body: some View {
        Form {
            Section("Sync") {
                LabeledContent("Status", value: viewModel.syncStatusText)

                if let lastSync = viewModel.lastSyncDate {
                    LabeledContent("Last Synced") {
                        Text(lastSync, style: .relative)
                    }
                }

                Button {
                    Task { await viewModel.syncNow() }
                } label: {
                    HStack {
                        Text("Sync Now")
                        if viewModel.isSyncing {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(viewModel.isSyncing)
            }

            Section("Data") {
                ShareLink(item: exportJSON(), preview: SharePreview("MacTodo Export", image: Image(systemName: "square.and.arrow.up")))  {
                    Label("Export Data", systemImage: "square.and.arrow.up")
                }
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Storage", value: "Azure Blob Storage")
            }
        }
        .navigationTitle("Settings")
        .task {
            await viewModel.refresh()
        }
    }

    private func exportJSON() -> String {
        // Synchronous placeholder — real export is async
        "MacTodo data export"
    }
}
