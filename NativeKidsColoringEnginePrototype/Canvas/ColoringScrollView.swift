import UIKit

@MainActor
final class ColoringScrollView: UIScrollView, UIScrollViewDelegate {
    let pageView: ColoringPageView

    private var lastLayoutSize = CGSize.zero
    private var hasInitialScale = false

    init(document: ColoringDocument) {
        self.pageView = ColoringPageView(document: document)
        super.init(frame: .zero)

        delegate = self
        backgroundColor = .systemGroupedBackground
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        bounces = true
        bouncesZoom = true
        decelerationRate = .fast
        delaysContentTouches = false
        canCancelContentTouches = true
        contentInsetAdjustmentBehavior = .never
        panGestureRecognizer.minimumNumberOfTouches = 2
        panGestureRecognizer.maximumNumberOfTouches = 2
        accessibilityHint = "Use two fingers to pan or pinch to zoom"

        addSubview(pageView)
        pageView.frame = CGRect(origin: .zero, size: document.page.pixelSize)
        contentSize = document.page.pixelSize
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        let sizeChanged = bounds.size != lastLayoutSize
        var centerInPage = CGPoint(x: pageView.bounds.midX, y: pageView.bounds.midY)
        var relativeZoom: CGFloat = 1

        if hasInitialScale, minimumZoomScale > 0 {
            centerInPage = pageView.convert(CGPoint(x: bounds.midX, y: bounds.midY), from: self)
            relativeZoom = zoomScale / minimumZoomScale
        }

        super.layoutSubviews()

        if sizeChanged, bounds.width > 0, bounds.height > 0 {
            let fitScale = min(bounds.width / pageView.bounds.width, bounds.height / pageView.bounds.height)
            minimumZoomScale = fitScale
            maximumZoomScale = fitScale * 5
            let newZoom = hasInitialScale ? min(max(fitScale * relativeZoom, minimumZoomScale), maximumZoomScale) : fitScale
            setZoomScale(newZoom, animated: false)
            hasInitialScale = true
            lastLayoutSize = bounds.size
            updateCenteringInsets()
            restoreVisibleCenter(centerInPage)
        } else {
            updateCenteringInsets()
        }
        pageView.inputConfiguration.zoomScale = zoomScale
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        pageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateCenteringInsets()
        pageView.inputConfiguration.zoomScale = zoomScale
    }

    override func touchesShouldCancel(in view: UIView) -> Bool {
        true
    }

    private func updateCenteringInsets() {
        let horizontal = max(0, (bounds.width - contentSize.width) / 2)
        let vertical = max(0, (bounds.height - contentSize.height) / 2)
        contentInset = UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal)
    }

    private func restoreVisibleCenter(_ pagePoint: CGPoint) {
        let proposed = CGPoint(
            x: pagePoint.x * zoomScale - bounds.width / 2,
            y: pagePoint.y * zoomScale - bounds.height / 2
        )
        let minX = -contentInset.left
        let minY = -contentInset.top
        let maxX = max(minX, contentSize.width - bounds.width + contentInset.right)
        let maxY = max(minY, contentSize.height - bounds.height + contentInset.bottom)
        contentOffset = CGPoint(
            x: min(max(proposed.x, minX), maxX),
            y: min(max(proposed.y, minY), maxY)
        )
    }
}
