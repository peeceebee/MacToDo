import SwiftUI
import Storage
import ViewModels

struct SettingsView: View {
    @State private var viewModel: SettingsViewModel

    init(store: WorkspaceStore) {
        _viewModel = State(initialValue: SettingsViewModel(store: store, localCache: LocalCacheService()))
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
}
