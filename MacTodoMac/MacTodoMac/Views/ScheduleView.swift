import SwiftUI
import Models
import ViewModels

struct ScheduleView: View {
    let store: WorkspaceStore

    @State private var showingAddPanel = false
    @State private var dayRange: Int = 7          // cycles 7 → 14 → 30
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
        VStack(spacing: 0) {
            // ── Header bar ──────────────────────────────────────────
            HStack {
                Text("Schedule")
                    .font(.title2.weight(.semibold))

                Spacer()

                // Day-range badge: circle with 7 / 14 / 30
                Button {
                    cycleDayRange()
                } label: {
                    ZStack {
                        Circle()
                            .strokeBorder(.secondary, lineWidth: 1.5)
                            .frame(width: 28, height: 28)
                        Text("\(dayRange)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                }
                .buttonStyle(.plain)
                .help("Showing next \(dayRange) days — click to change")

                // Add / close panel button
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingAddPanel.toggle()
                        if !showingAddPanel { resetForm() }
                    }
                } label: {
                    Image(systemName: showingAddPanel ? "xmark" : "plus")
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(.borderless)
                .help(showingAddPanel ? "Cancel" : "Add event")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // ── Add panel ───────────────────────────────────────────
            if showingAddPanel {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Event title", text: $newTitle)
                        .textFieldStyle(.roundedBorder)

                    DatePicker("Date", selection: $newDate, displayedComponents: [.date])
                        .labelsHidden()

                    Picker("Type", selection: $newType) {
                        ForEach(ScheduleEventType.allCases, id: \.self) { t in
                            Label(t.rawValue, systemImage: t.icon).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button("Add Event") {
                        guard !newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                        let event = ScheduleEvent(
                            title: newTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                            date: newDate,
                            type: newType
                        )
                        Task {
                            await store.addScheduleEvent(event)
                            withAnimation { showingAddPanel = false }
                            resetForm()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))

                Divider()
            }

            // ── Event list ──────────────────────────────────────────
            List {
                if filteredEvents.isEmpty {
                    ContentUnavailableView(
                        "No Events in \(dayRange) Days",
                        systemImage: "calendar",
                        description: Text("Press + to add a birthday, anniversary, or other event.")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredEvents) { event in
                        HStack(spacing: 10) {
                            Image(systemName: event.type.icon)
                                .foregroundStyle(iconColor(event.type))
                                .frame(width: 20)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.body)
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
                            .help("Remove event")
                        }
                        .padding(.vertical, 2)
                    }
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
