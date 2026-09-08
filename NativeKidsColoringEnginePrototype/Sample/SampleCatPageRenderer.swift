import CoreGraphics

/// Produces the one canonical Phase 0 page. Every coloring area is bounded by a thick,
/// closed black contour so segmentation behavior is repeatable across devices.
enum SampleCatPageRenderer {
    static let canvasSize = CGSize(width: 1024, height: 1024)

    static func render() -> CGImage {
        let width = Int(canvasSize.width)
        let height = Int(canvasSize.height)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let info = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: info
        ) else {
            preconditionFailure("Unable to make the sample page context")
        }

        // Make page geometry use UIKit-style top-left coordinates.
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.setLineWidth(18)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setStrokeColor(CGColor(gray: 0, alpha: 1))
        context.setFillColor(CGColor(gray: 0, alpha: 1))

        // Tail is behind the body and has its own closed interior.
        let tail = CGMutablePath()
        tail.move(to: CGPoint(x: 660, y: 690))
        tail.addCurve(to: CGPoint(x: 888, y: 590), control1: CGPoint(x: 752, y: 612), control2: CGPoint(x: 845, y: 598))
        tail.addCurve(to: CGPoint(x: 908, y: 742), control1: CGPoint(x: 946, y: 606), control2: CGPoint(x: 949, y: 700))
        tail.addCurve(to: CGPoint(x: 758, y: 832), control1: CGPoint(x: 867, y: 786), control2: CGPoint(x: 814, y: 822))
        tail.addLine(to: CGPoint(x: 705, y: 784))
        tail.addCurve(to: CGPoint(x: 820, y: 699), control1: CGPoint(x: 757, y: 769), control2: CGPoint(x: 799, y: 738))
        tail.addCurve(to: CGPoint(x: 681, y: 756), control1: CGPoint(x: 787, y: 704), control2: CGPoint(x: 722, y: 733))
        tail.closeSubpath()
        context.addPath(tail)
        context.strokePath()

        // Ears are intentionally independently closed before the head is added.
        strokeClosedPath(context, points: [
            CGPoint(x: 294, y: 267), CGPoint(x: 331, y: 74), CGPoint(x: 480, y: 214)
        ])
        strokeClosedPath(context, points: [
            CGPoint(x: 544, y: 214), CGPoint(x: 694, y: 74), CGPoint(x: 731, y: 267)
        ])

        // Head.
        context.strokeEllipse(in: CGRect(x: 246, y: 186, width: 532, height: 430))

        // Body and belly form two large nested test regions.
        context.strokeEllipse(in: CGRect(x: 334, y: 548, width: 356, height: 394))
        context.strokeEllipse(in: CGRect(x: 400, y: 650, width: 224, height: 238))

        // Collar creates a narrow, closed region between head and body.
        let collar = CGPath(roundedRect: CGRect(x: 352, y: 555, width: 320, height: 55), cornerWidth: 24, cornerHeight: 24, transform: nil)
        context.addPath(collar)
        context.strokePath()

        // Paws stay independently fillable even after the body is colored.
        context.strokeEllipse(in: CGRect(x: 320, y: 846, width: 190, height: 112))
        context.strokeEllipse(in: CGRect(x: 514, y: 846, width: 190, height: 112))

        // Eyes and muzzle are closed face regions.
        context.strokeEllipse(in: CGRect(x: 354, y: 326, width: 86, height: 104))
        context.strokeEllipse(in: CGRect(x: 584, y: 326, width: 86, height: 104))
        context.strokeEllipse(in: CGRect(x: 407, y: 432, width: 105, height: 105))
        context.strokeEllipse(in: CGRect(x: 512, y: 432, width: 105, height: 105))

        // Solid pupils and nose remain immutable black details.
        context.fillEllipse(in: CGRect(x: 386, y: 362, width: 24, height: 38))
        context.fillEllipse(in: CGRect(x: 614, y: 362, width: 24, height: 38))
        strokeClosedPath(context, points: [
            CGPoint(x: 486, y: 453), CGPoint(x: 538, y: 453), CGPoint(x: 512, y: 485)
        ], fill: true)

        // Smile and whiskers are line details. Whiskers terminate at the head contour.
        context.move(to: CGPoint(x: 512, y: 484))
        context.addCurve(to: CGPoint(x: 466, y: 523), control1: CGPoint(x: 509, y: 510), control2: CGPoint(x: 487, y: 526))
        context.move(to: CGPoint(x: 512, y: 484))
        context.addCurve(to: CGPoint(x: 558, y: 523), control1: CGPoint(x: 515, y: 510), control2: CGPoint(x: 537, y: 526))
        context.move(to: CGPoint(x: 399, y: 477))
        context.addLine(to: CGPoint(x: 270, y: 455))
        context.move(to: CGPoint(x: 397, y: 510))
        context.addLine(to: CGPoint(x: 270, y: 531))
        context.move(to: CGPoint(x: 625, y: 477))
        context.addLine(to: CGPoint(x: 754, y: 455))
        context.move(to: CGPoint(x: 627, y: 510))
        context.addLine(to: CGPoint(x: 754, y: 531))
        context.strokePath()

        // Three short toe marks per paw; they do not alter the closed paw boundary.
        context.setLineWidth(13)
        for x in [378.0, 428.0, 572.0, 622.0] {
            context.move(to: CGPoint(x: x, y: 899))
            context.addLine(to: CGPoint(x: x, y: 938))
        }
        context.strokePath()

        guard let image = context.makeImage() else {
            preconditionFailure("Unable to render the sample page")
        }
        return image
    }

    private static func strokeClosedPath(_ context: CGContext, points: [CGPoint], fill: Bool = false) {
        guard let first = points.first else { return }
        let path = CGMutablePath()
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        context.addPath(path)
        if fill {
            context.fillPath()
        } else {
            context.strokePath()
        }
    }
}
