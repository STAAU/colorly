import UIKit

enum ThumbnailService {
    @MainActor static func make(from flattenedPNG: Data, side: CGFloat = 300) -> Data? {
        guard let source = UIImage(data: flattenedPNG) else { return nil }
        let format = UIGraphicsImageRendererFormat(); format.scale = 1; format.opaque = true
        return UIGraphicsImageRenderer(size: CGSize(width: side, height: side), format: format).image { _ in
            UIColor.white.setFill(); UIRectFill(CGRect(x: 0, y: 0, width: side, height: side))
            source.draw(in: CGRect(x: 0, y: 0, width: side, height: side))
        }.pngData()
    }
}
