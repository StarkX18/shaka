import PencilKit
import UIKit

enum CanvasSnapshot {
    /// Renders PencilKit stroke data to PNG for multimodal model analysis.
    static func pngBase64(from drawingData: Data, background: UIColor = .white) -> String? {
        guard let drawing = try? PKDrawing(data: drawingData) else { return nil }

        let bounds = drawing.bounds.isEmpty
            ? CGRect(x: 0, y: 0, width: 800, height: 600)
            : drawing.bounds.insetBy(dx: -40, dy: -40)

        let image = drawing.image(from: bounds, scale: 2.0)
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let composited = renderer.image { context in
            background.setFill()
            context.fill(CGRect(origin: .zero, size: bounds.size))
            image.draw(at: .zero)
        }

        return composited.pngData()?.base64EncodedString()
    }
}
