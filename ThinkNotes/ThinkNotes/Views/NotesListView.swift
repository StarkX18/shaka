import SwiftUI

struct NotesListView: View {
    @EnvironmentObject private var notesViewModel: NotesViewModel
    @State private var showNewNoteSheet = false
    @State private var showSettings = false

    var body: some View {
        List(selection: $notesViewModel.selectedNoteID) {
            Section("ThinkNotes") {
                ForEach(notesViewModel.notes) { note in
                    NoteRowView(note: note)
                        .tag(note.id)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                notesViewModel.deleteNote(note)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Notes")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showSettings = true
                } label: {
                    Image(systemName: "gearshape")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewNoteSheet = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showNewNoteSheet) {
            NewNoteSheet { title, description, theme in
                notesViewModel.createNote(title: title, description: description, theme: theme)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }
}

private struct NoteRowView: View {
    let note: Note

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(note.theme.accent)
                    .frame(width: 8, height: 8)
                Text(note.title)
                    .font(.headline)
                    .lineLimit(1)
            }
            if !note.noteDescription.isEmpty {
                Text(note.noteDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Text(note.updatedAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var apiKey: String = APIConfiguration.apiKey

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    SecureField("OpenAI API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocorrectionDisabled()
                } header: {
                    Text("AI Assistant")
                } footer: {
                    Text("Powers real-time hints, math help, code guidance, and diagram analysis. Without a key, offline heuristics and web snippets still work.")
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Model", value: APIConfiguration.defaultModel)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        APIConfiguration.saveAPIKey(apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
                        dismiss()
                    }
                }
            }
        }
    }
}
