import Foundation

enum PhotoSourceKind: String, Codable { case photoLibrary, camera }
enum PhotoColoringStyle: String, Codable, CaseIterable, Identifiable {
    case simple = "Simple", classic = "Classic", detailed = "Detailed"
    var id: String { rawValue }
    var difficulty: ColoringDifficulty { self == .simple ? .easy : self == .classic ? .medium : .detailed }
}
enum PhotoBackgroundMode: String, Codable, CaseIterable, Identifiable {
    case simplify = "Simplify", keep = "Keep"
    var id: String { rawValue }
}
enum PhotoGenerationStatus: String, Codable { case uploading, processing, cleaning, completed, failed }
enum PhotoGenerationFailure: String, Codable, Error, Identifiable {
    case corrupt, blank, tooSmall, unsupported, tooDark, invalidOutput, cameraDenied, cameraUnavailable, storage, cancelled, unknown
    var id: String { rawValue }
    var message: String {
        switch self {
        case .corrupt: "That image could not be read. Please choose another."
        case .blank: "This photo appears blank. Choose a photo with a clear subject."
        case .tooSmall: "This photo is too small. Choose a larger image."
        case .unsupported: "This image format is not supported."
        case .tooDark: "This photo is too dark. Try one with more light."
        case .invalidOutput: "We couldn’t make a color-ready page from this photo. Try another crop."
        case .cameraDenied: "Camera access is off. You can enable it in Settings or choose a photo."
        case .cameraUnavailable: "A camera isn’t available on this device."
        case .storage: "We couldn’t save this creation on your device."
        case .cancelled: "Photo preparation was cancelled."
        case .unknown: "Something went wrong. Please try again."
        }
    }
}
struct PhotoGenerationOptions: Codable, Hashable { var style: PhotoColoringStyle; var background: PhotoBackgroundMode }
struct PhotoGenerationRequest: Codable, Hashable { let preparedSourcePath: String; let source: PhotoSourceKind; let options: PhotoGenerationOptions }
struct PhotoGenerationRecord: Codable, Identifiable, Hashable {
    let id: UUID; var source: PhotoSourceKind; var options: PhotoGenerationOptions; var status: PhotoGenerationStatus
    var createdAt: Date; var updatedAt: Date; var preparedSourcePath: String?; var masterPath: String?; var thumbnailPath: String?
    var failure: PhotoGenerationFailure?; var isHiddenFromGallery: Bool
    var page: ColoringPage { ColoringPage(id:"photo-\(id.uuidString)",title:"Photo coloring page",categoryID:"photo",sourceKey:masterPath ?? "",thumbnailKey:thumbnailPath ?? "",difficulty:options.style.difficulty,isPremium:true,isFeatured:false,sortOrder:0,source:.photoGenerated,origin:GeneratedPageOrigin(generationID:id,prompt:"Photo creation",complexity:options.style == .simple ? .simple : options.style == .classic ? .medium : .detailed,remoteAssetReference:nil,localMasterPath:masterPath,localThumbnailPath:thumbnailPath)) }
}
enum PhotoGenerationPhase: Equatable {
    case idle, uploading, processing, cleaning, completed(UUID), failed(PhotoGenerationFailure)
    var isBusy: Bool { self == .uploading || self == .processing || self == .cleaning }
}
