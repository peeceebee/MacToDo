import SwiftUI
import Models
import Storage
import ViewModels

enum AppTab: Int, CaseIterable {
    case shopping
    case schedule
    case notes
    case todo

    var label: String {
        switch self {
        case .shopping: return "Shopping"
        case .schedule: return "Schedule"
        case .notes:    return "Notes"
        case .todo:     return "ToDo"
        }
    }

    var icon: String {
        switch self {
        case .shopping: return "cart.fill"
        case .schedule: return "calendar"
        case .notes:    return "note.text"
        case .todo:     return "checklist"
        }
    }
}

struct ContentView: View {
    let store: WorkspaceStore

    @State private var selectedTab: AppTab = .todo
    @State private var scheduleDayRange: Int = 7

    private let dayRangeOptions = [7, 14, 30]

    var body: some View {
        VStack(spacing: 0) {
            // ── Top title bar ──────────────────────────────────
            Text("GitErDone")
                .font(.title.weight(.bold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(.bar)

            Divider()

            // ── Content area ───────────────────────────────────
            NavigationStack {
                Group {
                    switch selectedTab {
                    case .shopping:
                        ShoppingListiOSView(store: store)
                    case .schedule:
                        ScheduleiOSView(store: store, dayRange: $scheduleDayRange)
                    case .notes:
                        NotesiOSView(store: store)
                    case .todo:
                        ProjectListView(store: store)
                    }
                }
            }

            Divider()

            // ── Bottom icon bar ────────────────────────────────
            HStack {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Button {
                        if tab == .schedule && selectedTab == .schedule {
                            cycleScheduleDayRange()
                        } else {
                            selectedTab = tab
                        }
                    } label: {
                        VStack(spacing: 3) {
                            ZStack {
                                Image(systemName: tab.icon)
                                    .font(.title2)

                                if tab == .schedule {
                                    Text("\(scheduleDayRange)")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1)
                                        .background(.red, in: Capsule())
                                        .offset(x: 12, y: -10)
                                }
                            }

                            Text(tab.label)
                                .font(.caption2)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(selectedTab == tab ? .blue : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 8)
            .background(.bar)
        }
    }

    private func cycleScheduleDayRange() {
        switch scheduleDayRange {
        case 7:  scheduleDayRange = 14
        case 14: scheduleDayRange = 30
        default: scheduleDayRange = 7
        }
    }
}
