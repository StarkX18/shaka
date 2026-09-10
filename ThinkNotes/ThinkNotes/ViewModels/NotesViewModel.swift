import Foundation
import SwiftUI

@MainActor
final class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var selectedNoteID: UUID?

    private let storageKey = "thinknotes_saved_notes"

    init() {
        load()
        if notes.isEmpty {
            notes = [sampleNote]
        }
        selectedNoteID = notes.first?.id
    }

    var selectedNote: Note? {
        get { notes.first { $0.id == selectedNoteID } }
        set {
            guard let newValue, let index = notes.firstIndex(where: { $0.id == newValue.id }) else { return }
            notes[index] = newValue
            persist()
        }
    }

    func createNote(title: String, description: String, theme: NoteTheme) {
        let note = Note(title: title, noteDescription: description, theme: theme)
        notes.insert(note, at: 0)
        selectedNoteID = note.id
        persist()
    }

    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        if selectedNoteID == note.id {
            selectedNoteID = notes.first?.id
        }
        persist()
    }

    func updateNote(_ note: Note) {
        guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
        var updated = note
        updated.updatedAt = Date()
        notes[index] = updated
        persist()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Note].self, from: data)
        else { return }
        notes = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(notes) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }

    private var sampleNote: Note {
        Note(
            title: "Conservatives vs Liberals",
            noteDescription: "Compare ideological frameworks — economics, social policy, role of government",
            theme: .parchment,
            textContent: """
            Conservatives vs liberals — key dimensions to explore:

            • Role of tradition vs progress
            • Economic: free markets vs regulation
            • Social safety nets
            """
        )
    }
}
