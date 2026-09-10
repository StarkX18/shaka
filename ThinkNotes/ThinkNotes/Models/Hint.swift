import Foundation

enum HintKind: String, Codable {
    case research
    case math
    case code
    case diagram
    case general
}

enum HintPriority: Int, Codable, Comparable {
    case low = 0
    case medium = 1
    case high = 2

    static func < (lhs: HintPriority, rhs: HintPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

struct Hint: Identifiable, Codable, Equatable {
    let id: UUID
    let kind: HintKind
    let title: String
    let body: String
    let priority: HintPriority
    let createdAt: Date
    var isPinned: Bool

    init(
        id: UUID = UUID(),
        kind: HintKind,
        title: String,
        body: String,
        priority: HintPriority = .medium,
        createdAt: Date = Date(),
        isPinned: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.priority = priority
        self.createdAt = createdAt
        self.isPinned = isPinned
    }
}

enum AssistantStatus: Equatable {
    case idle
    case analyzing
    case streaming
    case error(String)
}
