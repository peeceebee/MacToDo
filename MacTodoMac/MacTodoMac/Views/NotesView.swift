import SwiftUI
import Models
import ViewModels

struct NotesView: View {
    let store: WorkspaceStore

    @State private var showingAddPanel = false
    @State private var selectedNote: Note?
    @State private var newTitle = ""
    @State private var newContents = ""
    @State private var newContactInfo = ""

    private var sortedNotes: [Note] {
        store.notes.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Header bar ──────────────────────────────────────
            HStack {
                Text("Notes")
                    .font(.title2.weight(.semibold))

                Spacer()

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
                .help(showingAddPanel ? "Cancel" : "Add note")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // ── Add panel ───────────────────────────────────────
            if showingAddPanel {
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Title", text: $newTitle)
                        .textFieldStyle(.roundedBorder)

                    TextEditor(text: $newContents)
                        .frame(minHeight: 60)
                        .border(Color.secondary.opacity(0.3))

                    TextField("URL / Phone (optional)", text: $newContactInfo)
                        .textFieldStyle(.roundedBorder)

                    Button("Add Note") {
                        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !title.isEmpty else { return }
                        let note = Note(
                            title: title,
                            contents: newContents.trimmingCharacters(in: .whitespacesAndNewlines),
                            contactInfo: newContactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                ? nil
                                : newContactInfo.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                        Task {
                            await store.addNote(note)
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

            // ── Notes list / detail split ──────────────────────
            if sortedNotes.isEmpty {
                ContentUnavailableView(
                    "No Notes",
                    systemImage: "note.text",
                    description: Text("Press + to add a note.")
                )
                .listRowSeparator(.hidden)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HSplitView {
                    List(selection: $selectedNote) {
                        ForEach(sortedNotes) { note in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(note.title)
                                    .font(.body.weight(.medium))
                                if !note.contents.isEmpty {
                                    Text(note.contents)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                            .padding(.vertical, 2)
                            .tag(note)
                        }
                    }
                    .frame(minWidth: 200)

                    if let selected = selectedNote {
                        NoteDetailMacView(store: store, note: selected)
                            .id(selected.id)
                    } else {
                        ContentUnavailableView(
                            "Select a Note",
                            systemImage: "note.text",
                            description: Text("Choose a note from the list.")
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
        }
    }

    private func resetForm() {
        newTitle = ""
        newContents = ""
        newContactInfo = ""
    }
}

struct NoteDetailMacView: View {
    let store: WorkspaceStore
    let note: Note

    @State private var title: String
    @State private var contents: String
    @State private var contactInfo: String

    init(store: WorkspaceStore, note: Note) {
        self.store = store
        self.note = note
        _title = State(initialValue: note.title)
        _contents = State(initialValue: note.contents)
        _contactInfo = State(initialValue: note.contactInfo ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Title", text: $title)
                .textFieldStyle(.roundedBorder)
                .font(.title3.weight(.semibold))

            Text("Contents")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)

            TextEditor(text: $contents)
                .font(.body)
                .frame(minHeight: 100)
                .border(Color.secondary.opacity(0.3))

            TextField("URL / Phone", text: $contactInfo)
                .textFieldStyle(.roundedBorder)

            if !contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let trimmed = contactInfo.trimmingCharacters(in: .whitespacesAndNewlines)
                if let url = URL(string: trimmed), url.scheme != nil {
                    Link("Open Link", destination: url)
                }
            }

            Spacer()

            HStack {
                Spacer()
                Button("Delete Note", role: .destructive) {
                    Task { await store.deleteNote(id: note.id) }
                }
            }
        }
        .padding()
        .frame(minWidth: 300)
        .onChange(of: title) { saveChanges() }
        .onChange(of: contents) { saveChanges() }
        .onChange(of: contactInfo) { saveChanges() }
    }

    private func saveChanges() {
        var updated = note
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? note.title : title
        updated.contents = contents
        updated.contactInfo = contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? nil
            : contactInfo.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { await store.updateNote(updated) }
    }
}
