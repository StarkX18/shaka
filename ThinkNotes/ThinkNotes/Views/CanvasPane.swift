import SwiftUI

struct CanvasPane: View {
    @Binding var drawingData: Data?
    let theme: NoteTheme
    let onDrawingChange: (Data) -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            PencilCanvasView(
                drawingData: $drawingData,
                onDrawingChanged: onDrawingChange,
                canvasBackground: UIColor(theme.canvasBackground)
            )

            if drawingData == nil {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "pencil.and.scribble")
                        .font(.title2)
                        .foregroundStyle(theme.accent.opacity(0.6))
                    Text("Draw diagrams, HLD sketches, math visualizations")
                        .font(.subheadline)
                        .foregroundStyle(theme.foreground.opacity(0.35))
                }
                .padding(24)
                .allowsHitTesting(false)
            }
        }
        .background(theme.canvasBackground)
    }
}
