import SwiftUI

struct TextEditorPane: View {
    @Binding var text: String
    let theme: NoteTheme
    let onTextChange: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            if text.isEmpty {
                Text("Start typing — research topics, equations, pseudocode…")
                    .foregroundStyle(theme.foreground.opacity(0.35))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 20)
                    .allowsHitTesting(false)
            }

            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(.body)
                .foregroundStyle(theme.foreground)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: text) { _, _ in
                    onTextChange()
                }
        }
        .background(theme.background)
    }
}
