import CoreGraphics
import Foundation

enum ColoringDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", detailed = "Detailed"
    var id: String { rawValue }
}

struct ColoringPage: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let categoryID: String
    let sourceKey: String
    let thumbnailKey: String
    let difficulty: ColoringDifficulty
    let isPremium: Bool
    let isFeatured: Bool
    let sortOrder: Int
}

struct ColoringPageAsset {
    let page: ColoringPage
    let pixelSize: CGSize
    let lineArt: CGImage
    var width: Int { Int(pixelSize.width) }
    var height: Int { Int(pixelSize.height) }
}
