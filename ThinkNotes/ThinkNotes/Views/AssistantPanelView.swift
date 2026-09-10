import SwiftUI

struct AssistantPanelView: View {
    @ObservedObject var pipeline: HintPipeline
    let theme: NoteTheme
    let onRefresh: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            panelHeader
            Divider().opacity(0.3)
            contentArea
        }
        .background(theme.background.opacity(0.95))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(theme.accent.opacity(0.15))
                .frame(width: 1)
        }
    }

    private var panelHeader: some View {
        HStack {
            Label("Thinking Assistant", systemImage: "brain.head.profile")
                .font(.headline)
                .foregroundStyle(theme.foreground)

            Spacer()

            statusIndicator

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
            }
            .disabled(pipeline.status == .analyzing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    @ViewBuilder
    private var statusIndicator: some View {
        switch pipeline.status {
        case .idle:
            contentTypeBadge
        case .analyzing, .streaming:
            ProgressView()
                .controlSize(.small)
        case .error(let message):
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .help(message)
        }
    }

    private var contentTypeBadge: some View {
        Text(pipeline.lastContext.detectedType.rawValue.capitalized)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(theme.accent.opacity(0.15))
            .foregroundStyle(theme.accent)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var contentArea: some View {
        if pipeline.hints.isEmpty && pipeline.status == .idle {
            emptyState
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(pipeline.hints) { hint in
                        HintCardView(
                            hint: hint,
                            theme: theme,
                            onPin: { pipeline.pinHint(hint) },
                            onDismiss: { pipeline.dismissHint(hint) }
                        )
                    }
                }
                .padding(16)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "sparkles")
                .font(.largeTitle)
                .foregroundStyle(theme.accent.opacity(0.5))
            Text("Hints appear as you write or draw")
                .font(.subheadline)
                .foregroundStyle(theme.foreground.opacity(0.5))
                .multilineTextAlignment(.center)
            Text("Try a debate topic, an equation, pseudocode, or sketch an architecture diagram.")
                .font(.caption)
                .foregroundStyle(theme.foreground.opacity(0.35))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
        }
        .padding()
    }
}
