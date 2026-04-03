import SwiftUI
import Models
import ViewModels

struct NotesiOSView: View {
    let store: WorkspaceStore

    @State private var showingAddPanel = false
    @State private var newTitle = ""
    @State private var newContents = ""
    @State private var newContactInfo = ""

    private var sortedNotes: [Note] {
        store.notes.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    var body: some View {
        List {
            if showingAddPanel {
                Section {
                    TextField("Title", text: $newTitle)
                    TextField("Contents", text: $newContents, axis: .vertical)
                        .lineLimit(3...6)
                    TextField("URL / Phone (optional)", text: $newContactInfo)
                        .keyboardType(.default)

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
                            showingAddPanel = false
                            resetForm()
                        }
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if sortedNotes.isEmpty && !showingAddPanel {
                ContentUnavailableView(
                    "No Notes",
                    systemImage: "note.text",
                    description: Text("Tap + to add a note.")
                )
                .listRowSeparator(.hidden)
            } else {
                Section {
                    ForEach(sortedNotes) { note in
                        NavigationLink(value: note) {
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
                        }
                    }
                }
            }
        }
        .navigationTitle("Notes")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Note.self) { note in
            NoteDetailiOSView(store: store, note: note)
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
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

    private func resetForm() {
        newTitle = ""
        newContents = ""
        newContactInfo = ""
    }
}

struct NoteDetailiOSView: View {
    let store: WorkspaceStore
    let note: Note

    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var contents: String
    @State private var contactInfo: String
    @State private var showingDeleteConfirm = false

    init(store: WorkspaceStore, note: Note) {
        self.store = store
        self.note = note
        _title = State(initialValue: note.title)
        _contents = State(initialValue: note.contents)
        _contactInfo = State(initialValue: note.contactInfo ?? "")
    }

    var body: some View {
        Form {
            Section("Title") {
                TextField("Title", text: $title)
            }

            Section("Contents") {
                TextEditor(text: $contents)
                    .frame(minHeight: 120)
            }

            Section("URL / Phone") {
                TextField("URL or phone number", text: $contactInfo)
                    .keyboardType(.default)

                if !contactInfo.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let trimmed = contactInfo.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let url = URL(string: trimmed), url.scheme != nil {
                        Link("Open Link", destination: url)
                    } else if let phoneURL = URL(string: "tel:\(trimmed)") {
                        Link("Call \(trimmed)", destination: phoneURL)
                    }
                }
            }

            Section {
                Button("Delete Note", role: .destructive) {
                    showingDeleteConfirm = true
                }
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this note?", isPresented: $showingDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    await store.deleteNote(id: note.id)
                    dismiss()
                }
            }
        }
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
