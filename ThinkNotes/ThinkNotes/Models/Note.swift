import Foundation

struct Note: Identifiable, Codable, Equatable {
    var id: UUID
    var title: String
    var noteDescription: String
    var theme: NoteTheme
    var textContent: String
    var drawingData: Data?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "Untitled",
        noteDescription: String = "",
        theme: NoteTheme = .ink,
        textContent: String = "",
        drawingData: Data? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.noteDescription = noteDescription
        self.theme = theme
        self.textContent = textContent
        self.drawingData = drawingData
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
