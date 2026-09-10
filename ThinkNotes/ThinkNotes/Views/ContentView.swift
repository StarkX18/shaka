import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var notesViewModel: NotesViewModel

    var body: some View {
        NavigationSplitView {
            NotesListView()
        } detail: {
            if let note = notesViewModel.selectedNote {
                NoteEditorView(note: note)
            } else {
                ContentUnavailableView(
                    "Select a note",
                    systemImage: "note.text",
                    description: Text("Pick a note or create one to start thinking.")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
