import CoreGraphics
import Foundation

enum ColoringDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "Easy", medium = "Medium", detailed = "Detailed"
    var id: String { rawValue }
}

enum ColoringPageSource: String, Codable { case curated, generated, futurePhoto }

struct GeneratedPageOrigin: Codable, Hashable {
    let generationID: UUID
    let prompt: String
    let complexity: GenerationComplexity
    let remoteAssetReference: String?
    let localMasterPath: String?
    let localThumbnailPath: String?
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
    var source: ColoringPageSource = .curated
    var origin: GeneratedPageOrigin? = nil

    enum CodingKeys: String, CodingKey { case id, title, categoryID, sourceKey, thumbnailKey, difficulty, isPremium, isFeatured, sortOrder, source, origin }
    init(id: String, title: String, categoryID: String, sourceKey: String, thumbnailKey: String, difficulty: ColoringDifficulty, isPremium: Bool, isFeatured: Bool, sortOrder: Int, source: ColoringPageSource = .curated, origin: GeneratedPageOrigin? = nil) {
        self.id=id; self.title=title; self.categoryID=categoryID; self.sourceKey=sourceKey; self.thumbnailKey=thumbnailKey; self.difficulty=difficulty; self.isPremium=isPremium; self.isFeatured=isFeatured; self.sortOrder=sortOrder; self.source=source; self.origin=origin
    }
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id=try c.decode(String.self,forKey:.id); title=try c.decode(String.self,forKey:.title); categoryID=try c.decode(String.self,forKey:.categoryID); sourceKey=try c.decode(String.self,forKey:.sourceKey); thumbnailKey=try c.decode(String.self,forKey:.thumbnailKey); difficulty=try c.decode(ColoringDifficulty.self,forKey:.difficulty); isPremium=try c.decode(Bool.self,forKey:.isPremium); isFeatured=try c.decode(Bool.self,forKey:.isFeatured); sortOrder=try c.decode(Int.self,forKey:.sortOrder); source=try c.decodeIfPresent(ColoringPageSource.self,forKey:.source) ?? .curated; origin=try c.decodeIfPresent(GeneratedPageOrigin.self,forKey:.origin)
    }
}

struct ColoringPageAsset { let page: ColoringPage; let pixelSize: CGSize; let lineArt: CGImage; var width: Int { Int(pixelSize.width) }; var height: Int { Int(pixelSize.height) } }
