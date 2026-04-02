import SwiftUI
import Storage
import ViewModels

struct SettingsPane: View {
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

                Button("Sync Now") {
                    Task { await viewModel.syncNow() }
                }
                .disabled(viewModel.isSyncing)
            }

            Section("About") {
                LabeledContent("Version", value: "1.0.0")
                LabeledContent("Storage", value: "Azure Blob Storage")
            }
        }
        .formStyle(.grouped)
        .frame(width: 450)
        .task {
            await viewModel.refresh()
        }
    }
}
