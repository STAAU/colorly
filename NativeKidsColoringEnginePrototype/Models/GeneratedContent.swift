import Foundation

enum GenerationComplexity: String, Codable, CaseIterable, Identifiable {
    case simple = "Simple", medium = "Medium", detailed = "Detailed"
    var id: String { rawValue }
    var difficulty: ColoringDifficulty { self == .simple ? .easy : self == .medium ? .medium : .detailed }
}

enum GenerationStatus: String, Codable { case queued, generating, processing, completed, failed }

enum GenerationFailure: String, Codable, Error, Identifiable {
    case offline, timedOut, rejected, limitReached, provider, storage, unknown
    var id: String { rawValue }
    var message: String {
        switch self {
        case .offline: "You appear to be offline. Try again when connected."
        case .timedOut: "This is taking longer than expected. Please try again."
        case .rejected: "Try describing a friendly, all-ages scene."
        case .limitReached: "You’ve reached today’s creation limit."
        case .provider: "The art studio is busy. Please try again."
        case .storage: "We couldn’t save this page on your device."
        case .unknown: "Something went wrong. Your idea is still here."
        }
    }
}

struct GenerationRequest: Codable, Hashable { let prompt: String; let complexity: GenerationComplexity }
struct GenerationResponse: Codable { let identifier: UUID }

struct GeneratedPageRecord: Codable, Identifiable, Hashable {
    let id: UUID
    var prompt: String
    var complexity: GenerationComplexity
    var status: GenerationStatus
    var createdAt: Date
    var updatedAt: Date
    var masterPath: String?
    var thumbnailPath: String?
    var failure: GenerationFailure?
    var isHiddenFromGallery: Bool

    init(id: UUID, prompt: String, complexity: GenerationComplexity, status: GenerationStatus, createdAt: Date, updatedAt: Date, masterPath: String?, thumbnailPath: String?, failure: GenerationFailure?, isHiddenFromGallery: Bool = false) {
        self.id = id
        self.prompt = prompt
        self.complexity = complexity
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.masterPath = masterPath
        self.thumbnailPath = thumbnailPath
        self.failure = failure
        self.isHiddenFromGallery = isHiddenFromGallery
    }

    enum CodingKeys: String, CodingKey {
        case id, prompt, complexity, status, createdAt, updatedAt
        case masterPath, thumbnailPath, failure, isHiddenFromGallery
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        prompt = try values.decode(String.self, forKey: .prompt)
        complexity = try values.decode(GenerationComplexity.self, forKey: .complexity)
        status = try values.decode(GenerationStatus.self, forKey: .status)
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        updatedAt = try values.decode(Date.self, forKey: .updatedAt)
        masterPath = try values.decodeIfPresent(String.self, forKey: .masterPath)
        thumbnailPath = try values.decodeIfPresent(String.self, forKey: .thumbnailPath)
        failure = try values.decodeIfPresent(GenerationFailure.self, forKey: .failure)
        isHiddenFromGallery = try values.decodeIfPresent(Bool.self, forKey: .isHiddenFromGallery) ?? false
    }

    var page: ColoringPage {
        ColoringPage(id: "generated-\(id.uuidString)", title: prompt, categoryID: "generated", sourceKey: masterPath ?? "", thumbnailKey: thumbnailPath ?? "", difficulty: complexity.difficulty, isPremium: false, isFeatured: false, sortOrder: 0, source: .generated, origin: GeneratedPageOrigin(generationID: id, prompt: prompt, complexity: complexity, remoteAssetReference: nil, localMasterPath: masterPath, localThumbnailPath: thumbnailPath))
    }
}

enum AIGenerationPhase: Equatable {
    case idle, submitting, generating, processing, completed(UUID), failed(GenerationFailure)
    var isBusy: Bool { if case .submitting = self { return true }; if case .generating = self { return true }; if case .processing = self { return true }; return false }
}
