import CoreGraphics
import Foundation

@MainActor
final class PaintSurface {
    let width: Int
    let height: Int
    let bytesPerRow: Int

    private let context: CGContext

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        self.bytesPerRow = width * 4

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
            preconditionFailure("Unable to allocate the paint surface")
        }
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1, y: -1)
        context.setAllowsAntialiasing(true)
        context.setShouldAntialias(true)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        self.context = context
        clear()
    }

    func clear() {
        context.flush()
        guard let data = context.data else { return }
        memset(data, 0, bytesPerRow * height)
    }

    func flushDrawing() {
        context.flush()
    }

    func image() -> CGImage? {
        context.flush()
        return context.makeImage()
    }

    func paintSegment(from start: CGPoint, to end: CGPoint, diameter: CGFloat, color: RGBAColor, erasing: Bool) {
        context.saveGState()
        context.setLineWidth(diameter)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.setBlendMode(erasing ? .clear : .normal)
        context.setStrokeColor(color.cgColor)
        context.setFillColor(color.cgColor)

        if hypot(end.x - start.x, end.y - start.y) < 0.01 {
            let rect = CGRect(
                x: start.x - diameter / 2,
                y: start.y - diameter / 2,
                width: diameter,
                height: diameter
            )
            if erasing {
                context.clear(rect)
            } else {
                context.fillEllipse(in: rect)
            }
        } else {
            context.beginPath()
            context.move(to: start)
            context.addLine(to: end)
            context.strokePath()
        }
        context.restoreGState()
    }

    func fill(span: RegionSpan, color: RGBAColor) {
        guard let base = context.data?.assumingMemoryBound(to: UInt8.self) else { return }
        let start = span.y * bytesPerRow + span.startX * 4
        for x in span.startX...span.endX {
            let pixel = start + (x - span.startX) * 4
            base[pixel] = color.red
            base[pixel + 1] = color.green
            base[pixel + 2] = color.blue
            base[pixel + 3] = color.alpha
        }
    }

    func read(rect: CGRect) -> Data {
        let pixelRect = clampedPixelRect(rect)
        guard pixelRect.width > 0, pixelRect.height > 0,
              let source = context.data?.assumingMemoryBound(to: UInt8.self) else { return Data() }
        let rowByteCount = pixelRect.width * 4
        var result = Data(count: rowByteCount * pixelRect.height)
        result.withUnsafeMutableBytes { destination in
            guard let dst = destination.baseAddress else { return }
            for row in 0..<pixelRect.height {
                let sourceOffset = (pixelRect.y + row) * bytesPerRow + pixelRect.x * 4
                memcpy(dst.advanced(by: row * rowByteCount), source.advanced(by: sourceOffset), rowByteCount)
            }
        }
        return result
    }

    func write(rect: CGRect, pixels: Data) {
        let pixelRect = clampedPixelRect(rect)
        guard pixelRect.width > 0, pixelRect.height > 0,
              pixels.count == pixelRect.width * pixelRect.height * 4,
              let destination = context.data?.assumingMemoryBound(to: UInt8.self) else { return }
        let rowByteCount = pixelRect.width * 4
        pixels.withUnsafeBytes { source in
            guard let src = source.baseAddress else { return }
            for row in 0..<pixelRect.height {
                let destinationOffset = (pixelRect.y + row) * bytesPerRow + pixelRect.x * 4
                memcpy(destination.advanced(by: destinationOffset), src.advanced(by: row * rowByteCount), rowByteCount)
            }
        }
    }

    private func clampedPixelRect(_ rect: CGRect) -> (x: Int, y: Int, width: Int, height: Int) {
        let standardized = rect.standardized
        let minX = max(0, min(width, Int(floor(standardized.minX))))
        let minY = max(0, min(height, Int(floor(standardized.minY))))
        let maxX = max(minX, min(width, Int(ceil(standardized.maxX))))
        let maxY = max(minY, min(height, Int(ceil(standardized.maxY))))
        return (minX, minY, maxX - minX, maxY - minY)
    }
}
