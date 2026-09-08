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
    var projects:[ColoringProject]=[]; var favorites:Set<String>=[]; var generatedHistory:[GeneratedPageRecord]=[]
    var generationPhase:AIGenerationPhase = .idle
    var selectedTab=0
    @ObservationIgnored weak var activeEditor:ColoringViewModel?

    init() {
        generationService = LocalFixtureGenerationService(cache:generatedAssets)
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
        }
    }
    func page(id:String)->ColoringPage? { content.page(id:id) ?? generatedHistory.first(where:{$0.page.id==id})?.page }
    func image(for record:GeneratedPageRecord, thumbnail:Bool)->UIImage? { generatedAssets.image(path:thumbnail ? record.thumbnailPath:record.masterPath) }
    func asset(for page:ColoringPage, project:ColoringProject? = nil) async -> ColoringPageAsset? {
        if page.source == .curated { return artwork.asset(for:page) }
        if let project, let data=await storage.lineArt(for:project), let image=UIImage(data:data)?.cgImage { return ColoringPageAsset(page:page,pixelSize:CGSize(width:image.width,height:image.height),lineArt:image) }
        guard let image=generatedAssets.image(path:page.origin?.localMasterPath)?.cgImage else{return nil}; return ColoringPageAsset(page:page,pixelSize:CGSize(width:image.width,height:image.height),lineArt:image)
    }
    func toggleFavorite(_ id:String){ guard content.page(id:id) != nil else{return}; if favorites.contains(id){favorites.remove(id)}else{favorites.insert(id)}; favoritesService.save(favorites) }
    func project(for pageID:String)->ColoringProject?{projects.first{$0.pageID==pageID}}
    func makeProject(for page:ColoringPage)->ColoringProject {
        if let value=project(for:page.id){return value}; let now=Date(); let value=ColoringProject(id:page.id,pageID:page.id,createdAt:now,updatedAt:now,status:.inProgress,paintPath:"\(page.id)-paint.png",thumbnailPath:"\(page.id)-thumb.png",pixelWidth:1024,pixelHeight:1024); projects.append(value)
        Task { if page.source == .generated, let data=generatedAssets.image(path:page.origin?.localMasterPath)?.pngData(){try? await storage.saveLineArt(data,for:value)}; try? await storage.saveIndex(projects) }; return value
    }
    func generate(prompt: String, complexity: GenerationComplexity) {
        let clean = String(prompt.trimmingCharacters(in: .whitespacesAndNewlines).prefix(300))
        guard !clean.isEmpty, !generationPhase.isBusy else { return }
        let id = UUID()
        let now = Date()
        let draft = GeneratedPageRecord(id: id, prompt: clean, complexity: complexity, status: .queued, createdAt: now, updatedAt: now, masterPath: nil, thumbnailPath: nil, failure: nil)
        generatedHistory.insert(draft, at: 0)
        generationPhase = .submitting
        Task {
            try? await historyRepository.save(generatedHistory)
            try? await historyRepository.savePending(id)
            await completeGeneration(id: id, prompt: clean, complexity: complexity)
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

    func resetGeneration(){generationPhase = .idle}
    func update(_ project:ColoringProject){if let i=projects.firstIndex(where:{$0.id==project.id}){projects[i]=project}else{projects.append(project)}}
    func flushActiveEditor(){activeEditor?.flushSave()}
}
