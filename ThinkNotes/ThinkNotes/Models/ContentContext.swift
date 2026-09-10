import Foundation

enum DetectedContentType: String, Codable {
    case prose
    case research
    case math
    case pseudocode
    case codeRequest
    case diagram
    case mixed
}

struct ContentContext: Equatable {
    var text: String
    var hasDrawing: Bool
    var detectedType: DetectedContentType
    var targetLanguage: String?
    var researchTopic: String?
    var mathExpressions: [String]
    var triggerPhrase: String?

    static let empty = ContentContext(
        text: "",
        hasDrawing: false,
        detectedType: .prose,
        targetLanguage: nil,
        researchTopic: nil,
        mathExpressions: [],
        triggerPhrase: nil
    )
}
