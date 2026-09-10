import Foundation
import SwiftUI
import PencilKit

enum EditorPane: String, CaseIterable, Identifiable {
    case text
    case canvas
    case split

    var id: String { rawValue }

    var label: String {
        switch self {
        case .text: return "Text"
        case .canvas: return "Pencil"
        case .split: return "Split"
        }
    }

    var icon: String {
        switch self {
        case .text: return "doc.text"
        case .canvas: return "pencil.tip.crop.circle"
        case .split: return "rectangle.split.2x1"
        }
    }
}

@MainActor
final class NoteEditorViewModel: ObservableObject {
    @Published var textContent: String = ""
    @Published var drawingData: Data?
    @Published var activePane: EditorPane = .split
    @Published var showAssistantPanel: Bool = true

    let hintPipeline = HintPipeline()

    private var noteID: UUID?
    private var onSave: ((Note) -> Void)?
    private var currentNote: Note?

    func bind(to note: Note, onSave: @escaping (Note) -> Void) {
        guard noteID != note.id else { return }
        noteID = note.id
        currentNote = note
        self.onSave = onSave
        textContent = note.textContent
        drawingData = note.drawingData
        hintPipeline.clearUnpinnedHints()
        hintPipeline.scheduleAnalysis(
            text: textContent,
            drawingData: drawingData,
            noteTitle: note.title,
            noteDescription: note.noteDescription
        )
    }

    func textDidChange() {
        persistDraft()
        guard let note = currentNote else { return }
        hintPipeline.scheduleAnalysis(
            text: textContent,
            drawingData: drawingData,
            noteTitle: note.title,
            noteDescription: note.noteDescription
        )
    }

    func drawingDidChange(_ data: Data) {
        drawingData = data
        persistDraft()
        guard let note = currentNote else { return }
        hintPipeline.scheduleAnalysis(
            text: textContent,
            drawingData: drawingData,
            noteTitle: note.title,
            noteDescription: note.noteDescription
        )
    }

    func refreshHints() async {
        guard let note = currentNote else { return }
        await hintPipeline.runAnalysisImmediately(
            text: textContent,
            drawingData: drawingData,
            noteTitle: note.title,
            noteDescription: note.noteDescription
        )
    }

    private func persistDraft() {
        guard var note = currentNote else { return }
        note.textContent = textContent
        note.drawingData = drawingData
        currentNote = note
        onSave?(note)
    }
}
