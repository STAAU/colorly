import CoreGraphics
import Foundation

struct BoundaryMask: Sendable {
    let width: Int
    let height: Int
    /// One byte per pixel. A nonzero value is an immutable line-art barrier.
    let bytes: Data
}

enum BoundaryMaskBuilder {
    /// Includes faint antialiasing pixels and expands the contour by two pixels. The expansion
    /// is conservative by design: it prevents a one-pixel raster gap from leaking a fill.
    static func build(from lineArt: CGImage, width: Int, height: Int) -> BoundaryMask {
        let bytesPerRow = width * 4
        var rgba = Data(count: bytesPerRow * height)
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
        let info = CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue

        rgba.withUnsafeMutableBytes { storage in
            guard let context = CGContext(
                data: storage.baseAddress,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: info
            ) else { return }
            context.translateBy(x: 0, y: CGFloat(height))
            context.scaleBy(x: 1, y: -1)
            context.setBlendMode(.copy)
            context.draw(lineArt, in: CGRect(x: 0, y: 0, width: width, height: height))
        }

        var initial = Data(count: width * height)
        initial.withUnsafeMutableBytes { destination in
            rgba.withUnsafeBytes { source in
                guard
                    let dst = destination.bindMemory(to: UInt8.self).baseAddress,
                    let src = source.bindMemory(to: UInt8.self).baseAddress
                else { return }
                for index in 0..<(width * height) {
                    let pixel = src + index * 4
                    let alpha = Int(pixel[3])
                    // The source page only contains black line art. Luminance is retained here
                    // so this builder also behaves sensibly for future grayscale source pages.
                    let luminance = (54 * Int(pixel[0]) + 183 * Int(pixel[1]) + 19 * Int(pixel[2])) >> 8
                    dst[index] = alpha >= 5 && luminance < 248 ? 1 : 0
                }
            }
        }

        let radius = 2
        var horizontal = Data(count: width * height)
        initial.withUnsafeBytes { source in
            horizontal.withUnsafeMutableBytes { destination in
                guard
                    let src = source.bindMemory(to: UInt8.self).baseAddress,
                    let dst = destination.bindMemory(to: UInt8.self).baseAddress
                else { return }
                for y in 0..<height {
                    let row = y * width
                    var lastBarrier = -radius - 1
                    for x in 0..<width {
                        if src[row + x] != 0 { lastBarrier = x }
                        if x - lastBarrier <= radius { dst[row + x] = 1 }
                    }
                    lastBarrier = width + radius
                    for x in stride(from: width - 1, through: 0, by: -1) {
                        if src[row + x] != 0 { lastBarrier = x }
                        if lastBarrier - x <= radius { dst[row + x] = 1 }
                    }
                }
            }
        }

        var dilated = Data(count: width * height)
        horizontal.withUnsafeBytes { source in
            dilated.withUnsafeMutableBytes { destination in
                guard
                    let src = source.bindMemory(to: UInt8.self).baseAddress,
                    let dst = destination.bindMemory(to: UInt8.self).baseAddress
                else { return }
                for x in 0..<width {
                    var lastBarrier = -radius - 1
                    for y in 0..<height {
                        let index = y * width + x
                        if src[index] != 0 { lastBarrier = y }
                        if y - lastBarrier <= radius { dst[index] = 1 }
                    }
                    lastBarrier = height + radius
                    for y in stride(from: height - 1, through: 0, by: -1) {
                        let index = y * width + x
                        if src[index] != 0 { lastBarrier = y }
                        if lastBarrier - y <= radius { dst[index] = 1 }
                    }
                }
            }
        }

        return BoundaryMask(width: width, height: height, bytes: dilated)
    }
}
