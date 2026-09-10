import SwiftUI

enum NoteTheme: String, Codable, CaseIterable, Identifiable {
    case ink
    case parchment
    case midnight
    case forest
    case coral

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .ink: return "Ink"
        case .parchment: return "Parchment"
        case .midnight: return "Midnight"
        case .forest: return "Forest"
        case .coral: return "Coral"
        }
    }

    var background: Color {
        switch self {
        case .ink: return Color(red: 0.98, green: 0.98, blue: 0.99)
        case .parchment: return Color(red: 0.96, green: 0.93, blue: 0.86)
        case .midnight: return Color(red: 0.09, green: 0.10, blue: 0.14)
        case .forest: return Color(red: 0.93, green: 0.96, blue: 0.93)
        case .coral: return Color(red: 0.99, green: 0.95, blue: 0.94)
        }
    }

    var foreground: Color {
        switch self {
        case .midnight: return .white
        default: return Color(red: 0.12, green: 0.13, blue: 0.16)
        }
    }

    var accent: Color {
        switch self {
        case .ink: return Color(red: 0.20, green: 0.45, blue: 0.95)
        case .parchment: return Color(red: 0.55, green: 0.35, blue: 0.15)
        case .midnight: return Color(red: 0.45, green: 0.65, blue: 1.0)
        case .forest: return Color(red: 0.18, green: 0.55, blue: 0.35)
        case .coral: return Color(red: 0.92, green: 0.35, blue: 0.30)
        }
    }

    var canvasBackground: Color {
        switch self {
        case .midnight: return Color(red: 0.13, green: 0.14, blue: 0.18)
        default: return Color.white.opacity(0.85)
        }
    }
}
