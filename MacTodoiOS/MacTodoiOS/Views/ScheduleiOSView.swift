import SwiftUI
import Models
import ViewModels

struct ScheduleiOSView: View {
    let store: WorkspaceStore

    @State private var showingAddPanel = false
    @State private var dayRange: Int = 7
    @State private var newTitle = ""
    @State private var newDate = Date()
    @State private var newType: ScheduleEventType = .other

    private var windowEnd: Date {
        Calendar.current.date(byAdding: .day, value: dayRange, to: Date()) ?? Date()
    }

    private var filteredEvents: [ScheduleEvent] {
        let now = Date()
        return store.scheduleEvents
            .filter { $0.date >= now && $0.date <= windowEnd }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        List {
            // ── Add panel (first section when open) ─────────────────
            if showingAddPanel {
                Section {
                    TextField("Event title", text: $newTitle)

                    DatePicker("Date", selection: $newDate, displayedComponents: [.date])

                    Picker("Type", selection: $newType) {
                        ForEach(ScheduleEventType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }

                    Button("Add Event") {
                        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let event = ScheduleEvent(
                            title: newTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            date: newDate,
                            type: newType
                        )
                        Task {
                            await store.addScheduleEvent(event)
                            showingAddPanel = false
                            resetForm()
                        }
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            // ── Event list ──────────────────────────────────────────
            if filteredEvents.isEmpty && !showingAddPanel {
                ContentUnavailableView(
                    "No Events in \(dayRange) Days",
                    systemImage: "calendar",
                    description: Text("Tap + to add a birthday, anniversary, or other event.")
                )
                .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(filteredEvents) { event in
                        HStack(spacing: 10) {
                            Image(systemName: event.type.icon)
                                .foregroundStyle(iconColor(event.type))
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                Text(event.date, style: .date)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(event.type.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(iconColor(event.type).opacity(0.15))
                                .foregroundStyle(iconColor(event.type))
                                .clipShape(Capsule())

                            Button {
                                Task { await store.deleteScheduleEvent(id: event.id) }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Schedule")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Day-range badge
                Button {
                    cycleDayRange()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(.secondary, lineWidth: 1.5)
                            .frame(width: 26, height: 26)
                        Text("\(dayRange)")
                            .font(.system(size: 11, weight: .semibold))
                    }
                }

                // Add / dismiss button
                Button {
                    withAnimation {
                        showingAddPanel.toggle()
                        if !showingAddPanel { resetForm() }
                    }
                } label: {
                    Image(systemName: showingAddPanel ? "xmark" : "plus")
                }
            }
        }
    }

    private func cycleDayRange() {
        switch dayRange {
        case 7:  dayRange = 14
        case 14: dayRange = 30
        default: dayRange = 7
        }
    }

    private func resetForm() {
        newTitle = ""
        newDate = Date()
        newType = .other
    }

    private func iconColor(_ type: ScheduleEventType) -> Color {
        switch type {
        case .birthday:    return .pink
        case .anniversary: return .red
        case .other:       return .blue
        }
    }
}
