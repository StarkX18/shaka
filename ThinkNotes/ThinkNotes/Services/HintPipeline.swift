import Foundation

/// Orchestrates debounced, cancellable real-time analysis as the user types or draws.
@MainActor
final class HintPipeline: ObservableObject {
    @Published private(set) var hints: [Hint] = []
    @Published private(set) var status: AssistantStatus = .idle
    @Published private(set) var lastContext: ContentContext = .empty

    private let analyzer = ContentAnalyzer()
    private let assistant = AIAssistantService()
    private var analysisTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    private var generationID = UUID()

    var debounceInterval: Duration = .milliseconds(700)

    func scheduleAnalysis(text: String, drawingData: Data?, noteTitle: String, noteDescription: String) {
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: self.debounceInterval)
            guard !Task.isCancelled else { return }
            await self.runAnalysis(
                text: text,
                drawingData: drawingData,
                noteTitle: noteTitle,
                noteDescription: noteDescription
            )
        }
    }

    func runAnalysisImmediately(text: String, drawingData: Data?, noteTitle: String, noteDescription: String) async {
        debounceTask?.cancel()
        await runAnalysis(
            text: text,
            drawingData: drawingData,
            noteTitle: noteTitle,
            noteDescription: noteDescription
        )
    }

    func pinHint(_ hint: Hint) {
        guard let index = hints.firstIndex(where: { $0.id == hint.id }) else { return }
        hints[index].isPinned.toggle()
        hints.sort { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            return lhs.createdAt > rhs.createdAt
        }
    }

    func dismissHint(_ hint: Hint) {
        hints.removeAll { $0.id == hint.id && !$0.isPinned }
    }

    func clearUnpinnedHints() {
        hints.removeAll { !$0.isPinned }
    }

    private func runAnalysis(
        text: String,
        drawingData: Data?,
        noteTitle: String,
        noteDescription: String
    ) async {
        analysisTask?.cancel()
        let currentGeneration = UUID()
        generationID = currentGeneration

        let hasDrawing = drawingData != nil && !(drawingData?.isEmpty ?? true)
        let context = analyzer.analyze(text: text, hasDrawing: hasDrawing)
        lastContext = context

        guard !context.text.isEmpty || context.hasDrawing else {
            status = .idle
            hints.removeAll { !$0.isPinned }
            return
        }

        status = .analyzing

        analysisTask = Task { [weak self] in
            guard let self else { return }

            do {
                let newHints = try await self.assistant.generateHints(
                    context: context,
                    drawingData: drawingData,
                    noteTitle: noteTitle,
                    noteDescription: noteDescription
                )

                guard !Task.isCancelled, self.generationID == currentGeneration else { return }

                await MainActor.run {
                    let pinned = self.hints.filter(\.isPinned)
                    let merged = self.mergeHints(existing: pinned, incoming: newHints)
                    self.hints = merged
                    self.status = .idle
                }
            } catch {
                guard !Task.isCancelled, self.generationID == currentGeneration else { return }
                await MainActor.run {
                    self.status = .error(error.localizedDescription)
                }
            }
        }
    }

    private func mergeHints(existing pinned: [Hint], incoming: [Hint]) -> [Hint] {
        var result = pinned
        for hint in incoming {
            let isDuplicate = result.contains {
                $0.title == hint.title && $0.body == hint.body
            }
            if !isDuplicate {
                result.append(hint)
            }
        }
        return result.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned { return lhs.isPinned && !rhs.isPinned }
            if lhs.priority != rhs.priority { return lhs.priority > rhs.priority }
            return lhs.createdAt > rhs.createdAt
        }
    }
}
