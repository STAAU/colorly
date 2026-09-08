import SwiftUI

struct ColoringCanvasRepresentable: UIViewRepresentable {
    let document: ColoringDocument
    let tool: ColoringTool
    let color: RGBAColor
    let brushSize: BrushSize
    let fillEnabled: Bool
    let onEditFinished: () -> Void

    func makeUIView(context: Context) -> ColoringScrollView {
        let scrollView = ColoringScrollView(document: document)
        document.onInvalidate = { [weak pageView = scrollView.pageView] rect in
            pageView?.setNeedsDisplay(rect.insetBy(dx: -2, dy: -2))
        }
        scrollView.pageView.onEditFinished = onEditFinished
        applyConfiguration(to: scrollView)
        return scrollView
    }

    func updateUIView(_ scrollView: ColoringScrollView, context: Context) {
        scrollView.pageView.onEditFinished = onEditFinished
        applyConfiguration(to: scrollView)
    }

    private func applyConfiguration(to scrollView: ColoringScrollView) {
        scrollView.pageView.inputConfiguration.tool = tool
        scrollView.pageView.inputConfiguration.color = color
        scrollView.pageView.inputConfiguration.brushDiameter = brushSize.diameter
        scrollView.pageView.inputConfiguration.fillEnabled = fillEnabled
    }
}
