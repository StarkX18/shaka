import SwiftUI
import PencilKit

struct PencilCanvasView: UIViewRepresentable {
    @Binding var drawingData: Data?
    var onDrawingChanged: (Data) -> Void
    var canvasBackground: UIColor

    func makeCoordinator() -> Coordinator {
        Coordinator(onDrawingChanged: onDrawingChanged)
    }

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.delegate = context.coordinator
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = canvasBackground
        canvas.isOpaque = true
        canvas.tool = PKInkingTool(.pen, color: .label, width: 3)

        if let data = drawingData,
           let drawing = try? PKDrawing(data: data) {
            canvas.drawing = drawing
        }

        context.coordinator.attachToolPicker(to: canvas)
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        canvas.backgroundColor = canvasBackground

        if let data = drawingData,
           let drawing = try? PKDrawing(data: data),
           canvas.drawing != drawing,
           !context.coordinator.isUserDrawing {
            canvas.drawing = drawing
        }
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var onDrawingChanged: (Data) -> Void
        var isUserDrawing = false
        private var toolPicker: PKToolPicker?
        private var debounceTask: DebouncedTask = DebouncedTask()

        init(onDrawingChanged: @escaping (Data) -> Void) {
            self.onDrawingChanged = onDrawingChanged
        }

        func attachToolPicker(to canvas: PKCanvasView) {
            let picker = PKToolPicker()
            picker.setVisible(true, forFirstResponder: canvas)
            picker.addObserver(canvas)
            canvas.becomeFirstResponder()
            toolPicker = picker
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            isUserDrawing = true
            let data = canvasView.drawing.dataRepresentation()
            debounceTask.schedule(after: .milliseconds(400)) { [weak self] in
                self?.onDrawingChanged(data)
                self?.isUserDrawing = false
            }
        }
    }
}
