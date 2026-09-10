import Foundation

/// Multimodal thinking assistant — text, math, code, diagrams, and live research.
actor AIAssistantService {
    private let webSearch = WebSearchService.shared

    func generateHints(
        context: ContentContext,
        drawingData: Data?,
        noteTitle: String,
        noteDescription: String
    ) async throws -> [Hint] {
        if APIConfiguration.isConfigured {
            return try await generateWithModel(
                context: context,
                drawingData: drawingData,
                noteTitle: noteTitle,
                noteDescription: noteDescription
            )
        }

        return await generateOfflineHints(
            context: context,
            noteTitle: noteTitle,
            noteDescription: noteDescription
        )
    }

    // MARK: - Live model path

    private func generateWithModel(
        context: ContentContext,
        drawingData: Data?,
        noteTitle: String,
        noteDescription: String
    ) async throws -> [Hint] {
        var webContext = ""
        if context.detectedType == .research, let topic = context.researchTopic ?? extractTopic(from: context.text) {
            let results = await webSearch.search(query: topic)
            webContext = results.map { "• \($0.title): \($0.snippet)" }.joined(separator: "\n")
        }

        let systemPrompt = """
        You are ThinkNotes, an overpowered thinking companion embedded in an iPad notes app.
        The user writes with keyboard and Apple Pencil. Your job is to help them THINK — not replace them.

        Rules:
        - Give concise, actionable hints (2-4 sentences each).
        - Never write the full essay/code/diagram for them unless they explicitly asked for implementation.
        - For research topics: surface angles, definitions, counterarguments, and what to verify.
        - For math: suggest solution strategies, identify the technique, mention visualization ideas.
        - For pseudocode/code requests: explain the best approach, pitfalls, and structure — only show code snippets when they asked for a specific language implementation.
        - For diagrams: critique architecture gently — missing components, wrong arrows, naming issues.
        - Respond as JSON array: [{"kind":"research|math|code|diagram|general","title":"...","body":"...","priority":"low|medium|high"}]
        - Max 4 hints. No markdown fences.
        """

        var userPrompt = """
        Note title: \(noteTitle)
        Note description: \(noteDescription)
        Detected content type: \(context.detectedType.rawValue)
        """

        if !context.text.isEmpty {
            userPrompt += "\n\nUser text:\n\(context.text)"
        }

        if !context.mathExpressions.isEmpty {
            userPrompt += "\n\nMath expressions detected: \(context.mathExpressions.joined(separator: ", "))"
        }

        if let lang = context.targetLanguage {
            userPrompt += "\n\nTarget language requested: \(lang)"
        }

        if !webContext.isEmpty {
            userPrompt += "\n\nWeb research context:\n\(webContext)"
        }

        if context.hasDrawing, drawingData != nil {
            userPrompt += "\n\n[A diagram/sketch is attached — analyze it for HLD/architecture feedback.]"
        }

        var contentParts: [OpenAIChatRequest.Message.ContentPart] = [
            .text(userPrompt)
        ]

        if context.hasDrawing, let data = drawingData,
           let base64 = CanvasSnapshot.pngBase64(from: data) {
            contentParts.append(.image(base64PNG: base64))
        }

        let request = OpenAIChatRequest(
            model: context.hasDrawing ? APIConfiguration.visionModel : APIConfiguration.defaultModel,
            messages: [
                .init(role: "system", content: [.text(systemPrompt)]),
                .init(role: "user", content: contentParts)
            ],
            temperature: 0.4,
            max_tokens: 1200
        )

        let responseText = try await performChatRequest(request)
        return parseHints(from: responseText, fallbackKind: hintKind(for: context.detectedType))
    }

    private func performChatRequest(_ request: OpenAIChatRequest) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw AIServiceError.invalidResponse
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(APIConfiguration.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let http = response as? HTTPURLResponse else {
            throw AIServiceError.invalidResponse
        }

        guard (200..<300).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "HTTP \(http.statusCode)"
            throw AIServiceError.network(message)
        }

        let decoded = try JSONDecoder().decode(OpenAIChatResponse.self, from: data)
        guard let content = decoded.choices.first?.message.content else {
            throw AIServiceError.invalidResponse
        }
        return content
    }

    // MARK: - Offline / demo hints

    private func generateOfflineHints(
        context: ContentContext,
        noteTitle: String,
        noteDescription: String
    ) async -> [Hint] {
        switch context.detectedType {
        case .research:
            let topic = context.researchTopic ?? extractTopic(from: context.text) ?? noteTitle
            let results = await webSearch.search(query: topic)
            var hints: [Hint] = [
                Hint(
                    kind: .research,
                    title: "Research angles",
                    body: "Break '\(topic)' into definitions, historical context, strongest arguments on each side, and one steel-manned counterargument. What evidence would change your mind?",
                    priority: .high
                )
            ]
            if let first = results.first {
                hints.append(Hint(
                    kind: .research,
                    title: first.title,
                    body: first.snippet,
                    priority: .medium
                ))
            }
            hints.append(Hint(
                kind: .general,
                title: "Unlock live AI",
                body: "Add an OpenAI API key in Settings for deeper, contextual hints that follow your writing in real time.",
                priority: .low
            ))
            return hints

        case .math:
            let expr = context.mathExpressions.first ?? "your expression"
            return [
                Hint(
                    kind: .math,
                    title: "Solution strategy",
                    body: "For '\(expr)': identify the form (linear, quadratic, system?). Try isolation → substitution → graphing. Sketch axes to sanity-check intercepts and symmetry.",
                    priority: .high
                ),
                Hint(
                    kind: .math,
                    title: "Visualization",
                    body: "Plot both sides as separate functions and look for intersections. A quick number-line or sign chart helps with inequalities.",
                    priority: .medium
                )
            ]

        case .pseudocode, .codeRequest:
            let lang = context.targetLanguage ?? "your target language"
            return [
                Hint(
                    kind: .code,
                    title: "Structure first",
                    body: "Map pseudocode blocks to functions. Clarify inputs/outputs, edge cases, and loop invariants before writing \(lang).",
                    priority: .high
                ),
                Hint(
                    kind: .code,
                    title: "Implementation nudge",
                    body: context.targetLanguage != nil
                        ? "When you write 'implementation in \(lang)', I'll suggest idiomatic patterns, error handling, and time/space tradeoffs."
                        : "Try writing 'implementation in Java' (or Swift, Python…) after your pseudocode to get language-specific guidance.",
                    priority: .medium
                )
            ]

        case .diagram, .mixed:
            return [
                Hint(
                    kind: .diagram,
                    title: "Architecture checklist",
                    body: "Label data flow directions. Check for a single entry point, clear service boundaries, and where persistence/async jobs live. Missing load balancer or cache?",
                    priority: .high
                ),
                Hint(
                    kind: .diagram,
                    title: "Pencil + AI",
                    body: "Draw freely with Apple Pencil. With an API key, the assistant analyzes your sketch and nudges you on HLD mistakes in real time.",
                    priority: .medium
                )
            ]

        case .prose:
            return [
                Hint(
                    kind: .general,
                    title: "Keep thinking",
                    body: noteDescription.isEmpty
                        ? "Add a short description to this note — it helps the assistant understand your intent."
                        : "Given your focus ('\(noteDescription)'), try outlining 3 key claims before expanding each one.",
                    priority: .low
                )
            ]
        }
    }

    // MARK: - Parsing

    private struct RawHint: Decodable {
        let kind: String?
        let title: String
        let body: String
        let priority: String?
    }

    private func parseHints(from text: String, fallbackKind: HintKind) -> [Hint] {
        let cleaned = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8),
              let rawHints = try? JSONDecoder().decode([RawHint].self, from: data)
        else {
            return [Hint(kind: fallbackKind, title: "Assistant", body: cleaned, priority: .medium)]
        }

        return rawHints.map { raw in
            Hint(
                kind: HintKind(rawValue: raw.kind ?? fallbackKind.rawValue) ?? fallbackKind,
                title: raw.title,
                body: raw.body,
                priority: parsePriority(raw.priority)
            )
        }
    }

    private func parsePriority(_ value: String?) -> HintPriority {
        switch value?.lowercased() {
        case "high": return .high
        case "low": return .low
        default: return .medium
        }
    }

    private func hintKind(for type: DetectedContentType) -> HintKind {
        switch type {
        case .research: return .research
        case .math: return .math
        case .pseudocode, .codeRequest: return .code
        case .diagram, .mixed: return .diagram
        case .prose: return .general
        }
    }

    private func extractTopic(from text: String) -> String? {
        let line = text.components(separatedBy: .newlines).first { $0.count > 8 }
        return line.map { String($0.prefix(100)) }
    }
}
