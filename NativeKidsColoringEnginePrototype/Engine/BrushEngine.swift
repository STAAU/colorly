import CoreGraphics

@MainActor
enum BrushEngine {
    static func apply(
        to surface: PaintSurface,
        from start: CGPoint,
        to end: CGPoint,
        diameter: CGFloat,
        color: RGBAColor,
        erasing: Bool
    ) -> CGRect {
        let radius = diameter / 2 + 2
        let bounds = CGRect(
            x: min(start.x, end.x) - radius,
            y: min(start.y, end.y) - radius,
            width: abs(end.x - start.x) + radius * 2,
            height: abs(end.y - start.y) + radius * 2
        )
        surface.paintSegment(from: start, to: end, diameter: diameter, color: color, erasing: erasing)
        return bounds
    }
}
