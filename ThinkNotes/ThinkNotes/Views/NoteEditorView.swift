import SwiftUI

struct NoteEditorView: View {
    @EnvironmentObject private var notesViewModel: NotesViewModel
    @StateObject private var editorViewModel = NoteEditorViewModel()

    let note: Note

    var body: some View {
        let theme = note.theme

        HStack(spacing: 0) {
            editorArea(theme: theme)
                .frame(maxWidth: .infinity)

            if editorViewModel.showAssistantPanel {
                AssistantPanelView(
                    pipeline: editorViewModel.hintPipeline,
                    theme: theme,
                    onRefresh: {
                        Task { await editorViewModel.refreshHints() }
                    }
                )
                .frame(width: 340)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .background(theme.background)
        .animation(.easeInOut(duration: 0.25), value: editorViewModel.showAssistantPanel)
        .navigationTitle(note.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Picker("Pane", selection: $editorViewModel.activePane) {
                    ForEach(EditorPane.allCases) { pane in
                        Label(pane.label, systemImage: pane.icon).tag(pane)
                    }
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 220)

                Button {
                    editorViewModel.showAssistantPanel.toggle()
                } label: {
                    Image(systemName: editorViewModel.showAssistantPanel ? "sparkles" : "sparkles.slash")
                }
                .symbolEffect(.pulse, options: .repeating, isActive: editorViewModel.hintPipeline.status == .analyzing)
            }
        }
        .onAppear {
            editorViewModel.bind(to: note) { updated in
                notesViewModel.updateNote(updated)
            }
        }
        .onChange(of: note.id) { _, _ in
            editorViewModel.bind(to: note) { updated in
                notesViewModel.updateNote(updated)
            }
        }
    }

    @ViewBuilder
    private func editorArea(theme: NoteTheme) -> some View {
        VStack(spacing: 0) {
            if !note.noteDescription.isEmpty {
                Text(note.noteDescription)
                    .font(.subheadline)
                    .foregroundStyle(theme.foreground.opacity(0.65))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }

            Divider().opacity(0.3)

            switch editorViewModel.activePane {
            case .text:
                TextEditorPane(
                    text: $editorViewModel.textContent,
                    theme: theme,
                    onTextChange: editorViewModel.textDidChange
                )
            case .canvas:
                CanvasPane(
                    drawingData: $editorViewModel.drawingData,
                    theme: theme,
                    onDrawingChange: editorViewModel.drawingDidChange
                )
            case .split:
                HStack(spacing: 0) {
                    TextEditorPane(
                        text: $editorViewModel.textContent,
                        theme: theme,
                        onTextChange: editorViewModel.textDidChange
                    )
                    Divider().opacity(0.3)
                    CanvasPane(
                        drawingData: $editorViewModel.drawingData,
                        theme: theme,
                        onDrawingChange: editorViewModel.drawingDidChange
                    )
                }
            }
        }
    }
}
