import Foundation

struct WebSearchResult: Equatable {
    let title: String
    let snippet: String
    let url: String
}

/// Lightweight web context fetcher. Uses DuckDuckGo Instant Answer API (no key required).
/// Falls back to curated topic summaries when offline or rate-limited.
actor WebSearchService {
    static let shared = WebSearchService()

    func search(query: String, limit: Int = 4) async -> [WebSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        if let results = await fetchDuckDuckGo(query: trimmed, limit: limit), !results.isEmpty {
            return results
        }

        return fallbackResults(for: trimmed)
    }

    private func fetchDuckDuckGo(query: String, limit: Int) async -> [WebSearchResult]? {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.duckduckgo.com/?q=\(encoded)&format=json&no_html=1&skip_disambig=1")
        else { return nil }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                return nil
            }

            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return nil
            }

            var results: [WebSearchResult] = []

            if let abstract = json["AbstractText"] as? String, !abstract.isEmpty {
                let heading = (json["Heading"] as? String) ?? query
                let source = (json["AbstractURL"] as? String) ?? "duckduckgo.com"
                results.append(WebSearchResult(title: heading, snippet: abstract, url: source))
            }

            if let related = json["RelatedTopics"] as? [[String: Any]] {
                for topic in related.prefix(limit) {
                    if let text = topic["Text"] as? String,
                       let firstURL = topic["FirstURL"] as? String {
                        let title = String(text.prefix(80))
                        results.append(WebSearchResult(title: title, snippet: text, url: firstURL))
                    }
                }
            }

            return Array(results.prefix(limit))
        } catch {
            return nil
        }
    }

    private func fallbackResults(for query: String) -> [WebSearchResult] {
        [
            WebSearchResult(
                title: "Explore: \(query)",
                snippet: "Connect your API key for live web research. The assistant can still help structure arguments, define terms, and suggest angles to explore.",
                url: "thinknotes://offline"
            )
        ]
    }
}
