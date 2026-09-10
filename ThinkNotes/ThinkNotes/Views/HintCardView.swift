import SwiftUI

struct HintCardView: View {
    let hint: Hint
    let theme: NoteTheme
    let onPin: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                kindIcon
                    .font(.title3)
                    .foregroundStyle(kindColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(hint.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(theme.foreground)
                    Text(hint.body)
                        .font(.subheadline)
                        .foregroundStyle(theme.foreground.opacity(0.75))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)
            }

            HStack {
                priorityBadge
                Spacer()
                Button(action: onPin) {
                    Image(systemName: hint.isPinned ? "pin.fill" : "pin")
                        .font(.caption)
                }
                .foregroundStyle(hint.isPinned ? theme.accent : theme.foreground.opacity(0.4))

                if !hint.isPinned {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.caption)
                    }
                    .foregroundStyle(theme.foreground.opacity(0.4))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(theme.canvasBackground.opacity(theme == .midnight ? 1 : 0.9))
                .shadow(color: .black.opacity(0.06), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(kindColor.opacity(hint.isPinned ? 0.5 : 0.2), lineWidth: hint.isPinned ? 2 : 1)
        )
    }

    private var kindIcon: some View {
        Group {
            switch hint.kind {
            case .research: Image(systemName: "globe")
            case .math: Image(systemName: "function")
            case .code: Image(systemName: "chevron.left.forwardslash.chevron.right")
            case .diagram: Image(systemName: "square.on.square.dashed")
            case .general: Image(systemName: "lightbulb")
            }
        }
    }

    private var kindColor: Color {
        switch hint.kind {
        case .research: return .blue
        case .math: return .purple
        case .code: return .green
        case .diagram: return .orange
        case .general: return theme.accent
        }
    }

    @ViewBuilder
    private var priorityBadge: some View {
        if hint.priority == .high {
            Text("Key")
                .font(.caption2.weight(.bold))
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(kindColor.opacity(0.15))
                .foregroundStyle(kindColor)
                .clipShape(Capsule())
        }
    }
}
