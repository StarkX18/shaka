import Foundation

struct ContentAnalyzer {
    private static let mathPattern = #"(?m)(?:^|\s)(?:\\\[.*?\\\]|\\\(.*?\\\)|\$.*?\$|[0-9]+(?:\.[0-9]+)?\s*[\+\-\*/\^=]\s*[0-9a-zA-Z\.]+|[a-zA-Z]+\s*\([^\)]*\)\s*=|[∫∑∏√≤≥≠±∞])"#

    private static let pseudocodeKeywords = [
        "algorithm", "procedure", "function", "for each", "while", "if then",
        "return", "input", "output", "loop", "repeat until", "endif", "endfor"
    ]

    private static let codeRequestPattern = #"(?i)(?:implementation|implement|convert|translate|write\s+(?:this\s+)?in)\s+(?:to\s+)?([a-z#\+]+)"#

    private static let researchIndicators = [
        " vs ", " versus ", "compare", "debate", "political", "history of",
        "pros and cons", "arguments for", "arguments against", "analysis of"
    ]

    func analyze(text: String, hasDrawing: Bool) -> ContentContext {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = normalized.lowercased()

        let mathExpressions = extractMath(from: normalized)
        let targetLanguage = extractTargetLanguage(from: normalized)
        let researchTopic = extractResearchTopic(from: normalized)
        let triggerPhrase = extractTriggerPhrase(from: normalized)

        let detectedType: DetectedContentType

        if hasDrawing && normalized.isEmpty {
            detectedType = .diagram
        } else if hasDrawing && !normalized.isEmpty {
            detectedType = .mixed
        } else if targetLanguage != nil && looksLikePseudocode(lower) {
            detectedType = .codeRequest
        } else if !mathExpressions.isEmpty {
            detectedType = .math
        } else if looksLikePseudocode(lower) {
            detectedType = .pseudocode
        } else if researchTopic != nil || researchIndicators.contains(where: { lower.contains($0) }) {
            detectedType = .research
        } else if hasDrawing {
            detectedType = .diagram
        } else {
            detectedType = .prose
        }

        return ContentContext(
            text: normalized,
            hasDrawing: hasDrawing,
            detectedType: detectedType,
            targetLanguage: targetLanguage,
            researchTopic: researchTopic,
            mathExpressions: mathExpressions,
            triggerPhrase: triggerPhrase
        )
    }

    private func extractMath(from text: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: Self.mathPattern, options: []) else {
            return []
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, options: [], range: range).compactMap { match in
            guard let swiftRange = Range(match.range, in: text) else { return nil }
            let expr = String(text[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            return expr.isEmpty ? nil : expr
        }
    }

    private func extractTargetLanguage(from text: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: Self.codeRequestPattern, options: []) else {
            return nil
        }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        guard let match = regex.firstMatch(in: text, options: [], range: range),
              match.numberOfRanges > 1,
              let langRange = Range(match.range(at: 1), in: text)
        else { return nil }

        let lang = String(text[langRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        return lang.isEmpty ? nil : lang.capitalized
    }

    private func extractResearchTopic(from text: String) -> String? {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }
        guard let firstMeaningful = lines.first(where: { $0.count > 12 }) else { return nil }

        if firstMeaningful.lowercased().contains(" vs ") || firstMeaningful.lowercased().contains(" versus ") {
            return firstMeaningful
        }

        if researchIndicators.contains(where: { firstMeaningful.lowercased().contains($0) }) {
            return String(firstMeaningful.prefix(120))
        }

        return nil
    }

    private func extractTriggerPhrase(from text: String) -> String? {
        let lower = text.lowercased()
        let triggers = [
            "implementation in ",
            "implement in ",
            "convert to ",
            "translate to ",
            "write in "
        ]
        for trigger in triggers {
            if let range = lower.range(of: trigger) {
                let after = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                let language = after.components(separatedBy: .newlines).first ?? after
                if !language.isEmpty { return trigger + language }
            }
        }
        return nil
    }

    private func looksLikePseudocode(_ lower: String) -> Bool {
        let hits = Self.pseudocodeKeywords.filter { lower.contains($0) }.count
        let hasIndentStructure = lower.contains("    ") || lower.contains("\t")
        return hits >= 2 || (hits >= 1 && hasIndentStructure)
    }
}
