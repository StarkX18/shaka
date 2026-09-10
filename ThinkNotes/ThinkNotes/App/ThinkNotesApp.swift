import SwiftUI

@main
struct ThinkNotesApp: App {
    @StateObject private var notesViewModel = NotesViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(notesViewModel)
        }
    }
}
