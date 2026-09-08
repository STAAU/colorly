import CoreGraphics
import Foundation

/// Immutable source page. Paint is deliberately owned by `ColoringDocument`, not this value.
struct ColoringPage {
    let id: String
    let title: String
    let pixelSize: CGSize
    let lineArt: CGImage

    var width: Int { Int(pixelSize.width) }
    var height: Int { Int(pixelSize.height) }
}
