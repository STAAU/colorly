import UIKit

@MainActor
final class ColoringPageView: UIView {
    struct InputConfiguration {
        var tool: ColoringTool
        var color: RGBAColor
        var brushDiameter: CGFloat
        var zoomScale: CGFloat
        var fillEnabled: Bool
    }

    let document: ColoringDocument
    var inputConfiguration: InputConfiguration
    var onEditFinished: (() -> Void)?

    private weak var activeTouch: UITouch?
    private var touchStart = CGPoint.zero
    private var lastTouchPoint = CGPoint.zero
    private var sawMultipleTouches = false

    init(document: ColoringDocument) {
        self.document = document
        self.inputConfiguration = InputConfiguration(
            tool: .fill,
            color: PaletteColor.all[0].rgba,
            brushDiameter: BrushSize.medium.diameter,
            zoomScale: 1,
            fillEnabled: false
        )
        super.init(frame: CGRect(origin: .zero, size: document.page.pixelSize))
        backgroundColor = .white
        isOpaque = true
        isMultipleTouchEnabled = true
        contentMode = .redraw
        accessibilityLabel = "Cat coloring page"
        layer.borderColor = UIColor.black.withAlphaComponent(0.12).cgColor
        layer.borderWidth = 1
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.clip(to: rect)
        document.draw(in: context)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let activeTouches = event?.allTouches?.filter { $0.phase == .began || $0.phase == .moved || $0.phase == .stationary } ?? []
        if activeTouches.count > 1 {
            sawMultipleTouches = true
            document.cancelStroke()
            activeTouch = nil
            return
        }
        guard activeTouch == nil, let touch = touches.first(where: isDrawingTouch) else { return }

        activeTouch = touch
        sawMultipleTouches = false
        let point = touch.location(in: self)
        touchStart = point
        lastTouchPoint = point

        switch inputConfiguration.tool {
        case .fill:
            break // Fill waits for a true single-touch tap in touchesEnded.
        case .brush, .eraser:
            document.beginStroke(
                at: point,
                color: inputConfiguration.color,
                diameter: inputConfiguration.brushDiameter,
                erasing: inputConfiguration.tool == .eraser
            )
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch, touches.contains(activeTouch), !sawMultipleTouches else { return }
        guard inputConfiguration.tool != .fill else {
            lastTouchPoint = activeTouch.location(in: self)
            return
        }

        let samples = event?.coalescedTouches(for: activeTouch) ?? [activeTouch]
        for sample in samples {
            let point = sample.location(in: self)
            document.continueStroke(to: point)
            lastTouchPoint = point
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch, touches.contains(activeTouch) else { return }
        defer { self.activeTouch = nil }

        if sawMultipleTouches {
            document.cancelStroke()
            return
        }

        let end = activeTouch.location(in: self)
        lastTouchPoint = end
        switch inputConfiguration.tool {
        case .fill:
            let screenMovement = hypot(end.x - touchStart.x, end.y - touchStart.y) * max(inputConfiguration.zoomScale, 0.001)
            if screenMovement <= 14, inputConfiguration.fillEnabled,
               document.fill(at: end, color: inputConfiguration.color) {
                onEditFinished?()
            }
        case .brush, .eraser:
            document.continueStroke(to: end)
            document.finishStroke()
            onEditFinished?()
        }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let activeTouch, touches.contains(activeTouch) else { return }
        document.cancelStroke()
        self.activeTouch = nil
    }

    private func isDrawingTouch(_ touch: UITouch) -> Bool {
        touch.type == .direct || touch.type == .pencil
    }
}
