import Foundation
import Observation
import UIKit

@MainActor @Observable final class AppModel {
    let content = LocalContentRepository()
    let artwork = LocalArtworkProvider()
    let storage = ProjectStorageService()
    let generatedAssets = GeneratedAssetCache()
    private let favoritesService = FavoritesService()
    private let historyRepository = GeneratedHistoryRepository()
    private var generationService: any AIGenerationService
    let photoAssets = PhotoAssetRepository()
    let subscriptions = SubscriptionManager()
    @ObservationIgnored private lazy var generationAccess = GenerationAccessService(client: subscriptions.supabase, supabaseURL: SubscriptionManager.supabaseURL, apiKey: SubscriptionManager.supabaseKey)
    var showsPaywall = false
    var paywallContext: String?
    private let photoRepository = PhotoHistoryRepository()
    private var photoService: any PhotoGenerationService
    var projects:[ColoringProject]=[]; var favorites:Set<String>=[]; var generatedHistory:[GeneratedPageRecord]=[]; var photoHistory:[PhotoGenerationRecord]=[]
    var generationPhase:AIGenerationPhase = .idle
    var photoPhase:PhotoGenerationPhase = .idle
    var selectedTab=0
    @ObservationIgnored weak var activeEditor:ColoringViewModel?

    init() {
        generationService = LocalFixtureGenerationService(cache:generatedAssets)
        photoService = LocalFixturePhotoGenerationService(assets: photoAssets)
        favorites=favoritesService.load(validIDs:Set(content.pages.map(\.id)))
        Task {
            async let loadedProjects = storage.loadProjects()
            async let loadedHistory = historyRepository.load()
            async let pending = historyRepository.loadPending()
            let (diskProjects, history, pendingID) = await (loadedProjects, loadedHistory, pending)

            var projectMap = Dictionary(uniqueKeysWithValues: diskProjects.map { ($0.id, $0) })
            projects.forEach { projectMap[$0.id] = $0 }
            projects = projectMap.values.sorted { $0.updatedAt > $1.updatedAt }

            var historyMap = Dictionary(uniqueKeysWithValues: history.map { ($0.id, $0) })
            generatedHistory.forEach { historyMap[$0.id] = $0 }
            generatedHistory = historyMap.values.sorted { $0.updatedAt > $1.updatedAt }

            if let pendingID, let record = generatedHistory.first(where: { $0.id == pendingID }) {
                await completeGeneration(id: pendingID, prompt: record.prompt, complexity: record.complexity)
            } else if pendingID != nil {
                try? await historyRepository.savePending(nil)
                generationPhase = .failed(.unknown)
            }
            let savedPhotos = await photoRepository.load()
            var photoMap = Dictionary(uniqueKeysWithValues: savedPhotos.map { ($0.id, $0) })
            photoHistory.forEach { photoMap[$0.id] = $0 }
            photoHistory = photoMap.values.sorted { $0.updatedAt > $1.updatedAt }
            let pendingPhotoID = await photoRepository.pending()
            if let photoID = pendingPhotoID, let record = photoHistory.first(where: { $0.id == photoID }), let path = record.preparedSourcePath {
                await completePhoto(id: photoID, request: PhotoGenerationRequest(preparedSourcePath:path,source:record.source,options:record.options))
            } else if pendingPhotoID != nil { try? await photoRepository.setPending(nil) }
        }
    }
    func presentPaywall(context: String? = nil) { paywallContext = context; showsPaywall = true }
    func canStart(_ page: ColoringPage) -> Bool { page.source != .curated || !page.isPremium || subscriptions.access.hasPremium || project(for: page.id) != nil }
    func page(id:String)->ColoringPage? { content.page(id:id) ?? generatedHistory.first(where:{$0.page.id==id})?.page ?? photoHistory.first(where:{$0.page.id==id})?.page }
    func image(for record:GeneratedPageRecord, thumbnail:Bool)->UIImage? { generatedAssets.image(path:thumbnail ? record.thumbnailPath:record.masterPath) }
    func asset(for page:ColoringPage, project:ColoringProject? = nil) async -> ColoringPageAsset? {
        if page.source == .curated { return artwork.asset(for:page) }
        if let project, let data=await storage.lineArt(for:project), let image=UIImage(data:data)?.cgImage { return ColoringPageAsset(page:page,pixelSize:CGSize(width:image.width,height:image.height),lineArt:image) }
        let sourceImage = page.source == .photoGenerated ? photoAssets.image(path:page.origin?.localMasterPath) : generatedAssets.image(path:page.origin?.localMasterPath)
        guard let image=sourceImage?.cgImage else{return nil}; return ColoringPageAsset(page:page,pixelSize:CGSize(width:image.width,height:image.height),lineArt:image)
    }
    func toggleFavorite(_ id:String){ guard content.page(id:id) != nil else{return}; if favorites.contains(id){favorites.remove(id)}else{favorites.insert(id)}; favoritesService.save(favorites) }
    func project(for pageID:String)->ColoringProject?{projects.first{$0.pageID==pageID}}
    func makeProject(for page:ColoringPage)->ColoringProject {
        if let value=project(for:page.id){return value}; let now=Date(); let value=ColoringProject(id:page.id,pageID:page.id,createdAt:now,updatedAt:now,status:.inProgress,paintPath:"\(page.id)-paint.png",thumbnailPath:"\(page.id)-thumb.png",pixelWidth:1024,pixelHeight:1024); projects.append(value)
        Task { if page.source != .curated { let image = page.source == .photoGenerated ? photoAssets.image(path:page.origin?.localMasterPath) : generatedAssets.image(path:page.origin?.localMasterPath); if let data=image?.pngData(){try? await storage.saveLineArt(data,for:value)} }; try? await storage.saveIndex(projects) }; return value
    }
    func generate(prompt: String, complexity: GenerationComplexity) {
        let clean = String(prompt.trimmingCharacters(in: .whitespacesAndNewlines).prefix(300))
        guard !clean.isEmpty, !generationPhase.isBusy else { return }
        generationPhase = .submitting
        Task {
            do {
                try await generationAccess.authorize(.textAI)
                let id = UUID()
                let now = Date()
                let draft = GeneratedPageRecord(id: id, prompt: clean, complexity: complexity, status: .queued, createdAt: now, updatedAt: now, masterPath: nil, thumbnailPath: nil, failure: nil)
                generatedHistory.insert(draft, at: 0)
                try await historyRepository.save(generatedHistory)
                try await historyRepository.savePending(id)
                await completeGeneration(id: id, prompt: clean, complexity: complexity)
            } catch GenerationAccessError.limitReached {
                generationPhase = .failed(.limitReached)
            } catch {
                generationPhase = .failed(.offline)
            }
        }
    }

    private func completeGeneration(id: UUID, prompt: String, complexity: GenerationComplexity) async {
        generationPhase = .generating
        try? await Task.sleep(for: .milliseconds(350))
        generationPhase = .processing
        do {
            let request = GenerationRequest(prompt: prompt, complexity: complexity)
            let result = try await generationService.generate(request, id: id)
            if let index = generatedHistory.firstIndex(where: { $0.id == id }) {
                generatedHistory[index] = result
            } else {
                generatedHistory.insert(result, at: 0)
            }
            try await historyRepository.save(generatedHistory)
            try await historyRepository.savePending(nil)
            generationPhase = .completed(id)
        } catch {
            let failure = (error as? GenerationFailure) ?? .unknown
            if let index = generatedHistory.firstIndex(where: { $0.id == id }) {
                generatedHistory[index].status = .failed
                generatedHistory[index].failure = failure
                generatedHistory[index].updatedAt = Date()
            }
            try? await historyRepository.save(generatedHistory)
            try? await historyRepository.savePending(nil)
            generationPhase = .failed(failure)
        }
    }

    func delete(_ record: GeneratedPageRecord) {
        if let project = project(for: record.page.id) {
            let lineArt = generatedAssets.image(path: record.masterPath)?.pngData()
            if let index = generatedHistory.firstIndex(where: { $0.id == record.id }) {
                generatedHistory[index].isHiddenFromGallery = true
            }
            Task {
                if let lineArt {
                    do {
                        try await storage.saveLineArt(lineArt, for: project)
                        generatedAssets.delete(record)
                    } catch {
                        // Keep the source asset if the project copy could not be secured.
                    }
                }
                try? await historyRepository.save(generatedHistory)
            }
        } else {
            generatedAssets.delete(record)
            generatedHistory.removeAll { $0.id == record.id }
            Task { try? await historyRepository.save(generatedHistory) }
        }
    }

    func photoImage(for record:PhotoGenerationRecord,thumbnail:Bool)->UIImage? { photoAssets.image(path:thumbnail ? record.thumbnailPath:record.masterPath) }
    func restorePrepared(_ record:PhotoGenerationRecord)->PreparedPhoto? { guard let path=record.preparedSourcePath,let image=UIImage(contentsOfFile:path) else{return nil};return PreparedPhoto(image:image,preview:image,path:path,source:record.source) }
    func generatePhoto(prepared:PreparedPhoto,options:PhotoGenerationOptions) {
        guard !photoPhase.isBusy else { return }
        photoPhase = .uploading
        Task {
            do {
                try await generationAccess.authorize(.photoAI)
                let id = UUID(), now = Date()
                let request = PhotoGenerationRequest(preparedSourcePath:prepared.path,source:prepared.source,options:options)
                photoHistory.insert(PhotoGenerationRecord(id:id,source:prepared.source,options:options,status:.uploading,createdAt:now,updatedAt:now,preparedSourcePath:prepared.path,masterPath:nil,thumbnailPath:nil,failure:nil,isHiddenFromGallery:false),at:0)
                try await photoRepository.save(photoHistory)
                try await photoRepository.setPending(id)
                await completePhoto(id:id,request:request)
            } catch GenerationAccessError.limitReached {
                photoPhase = .failed(.limitReached)
            } catch {
                photoPhase = .failed(.offline)
            }
        }
    }
    private func completePhoto(id:UUID,request:PhotoGenerationRequest)async{photoPhase = .processing;try? await Task.sleep(for:.milliseconds(350));photoPhase = .cleaning;do{let result=try await photoService.generate(request,id:id);if let i=photoHistory.firstIndex(where:{$0.id==id}){photoHistory[i]=result}else{photoHistory.insert(result,at:0)};try await photoRepository.save(photoHistory);try await photoRepository.setPending(nil);photoPhase = .completed(id)}catch{let failure=(error as? PhotoGenerationFailure) ?? .unknown;if let i=photoHistory.firstIndex(where:{$0.id==id}){photoHistory[i].status = .failed;photoHistory[i].failure=failure;photoHistory[i].updatedAt=Date()};try? await photoRepository.save(photoHistory);try? await photoRepository.setPending(nil);photoPhase = .failed(failure)}}
    func delete(_ record: PhotoGenerationRecord) {
        if let project = project(for: record.page.id) {
            let lineArt = photoAssets.image(path: record.masterPath)?.pngData()
            if let index = photoHistory.firstIndex(where: { $0.id == record.id }) {
                photoHistory[index].isHiddenFromGallery = true
            }
            Task {
                if let lineArt {
                    do {
                        try await storage.saveLineArt(lineArt, for: project)
                        photoAssets.delete(record)
                        if let path = record.preparedSourcePath { try? FileManager.default.removeItem(atPath: path) }
                    } catch {
                        // Retain the source assets when the offline project copy cannot be secured.
                    }
                }
                try? await photoRepository.save(photoHistory)
            }
        } else {
            photoAssets.delete(record)
            if let path = record.preparedSourcePath { try? FileManager.default.removeItem(atPath: path) }
            photoHistory.removeAll { $0.id == record.id }
            Task { try? await photoRepository.save(photoHistory) }
        }
    }
    func resetPhotoGeneration(){photoPhase = .idle}
    func resetGeneration(){generationPhase = .idle}
    func update(_ project:ColoringProject){if let i=projects.firstIndex(where:{$0.id==project.id}){projects[i]=project}else{projects.append(project)}}
    func flushActiveEditor(){activeEditor?.flushSave()}
}
