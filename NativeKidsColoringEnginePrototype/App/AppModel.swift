import Foundation
import Observation

@MainActor @Observable
final class AppModel {
    let content = LocalContentRepository()
    let artwork = LocalArtworkProvider()
    let storage = ProjectStorageService()
    private let favoritesService = FavoritesService()
    var projects: [ColoringProject] = []
    var favorites: Set<String> = []
    var selectedTab = 0
    @ObservationIgnored weak var activeEditor: ColoringViewModel?

    init() {
        favorites = favoritesService.load(validIDs: Set(content.pages.map(\.id)))
        Task {
            let loaded = await storage.loadProjects()
            // A user can open a page while disk I/O is still in flight. Keep those
            // newer in-memory projects while adding everything found on disk.
            var merged = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
            projects.forEach { merged[$0.id] = $0 }
            projects = merged.values.sorted { $0.updatedAt > $1.updatedAt }
        }
    }

    func toggleFavorite(_ pageID: String) {
        guard content.page(id: pageID) != nil else { return }
        if favorites.contains(pageID) { favorites.remove(pageID) } else { favorites.insert(pageID) }
        favoritesService.save(favorites)
    }

    func project(for pageID: String) -> ColoringProject? { projects.first { $0.pageID == pageID } }

    func makeProject(for page: ColoringPage) -> ColoringProject {
        if let existing = project(for: page.id) { return existing }
        let now = Date()
        let value = ColoringProject(id: page.id, pageID: page.id, createdAt: now, updatedAt: now, status: .inProgress, paintPath: "\(page.id)-paint.png", thumbnailPath: "\(page.id)-thumb.png", pixelWidth: 1024, pixelHeight: 1024)
        projects.append(value)
        Task { try? await storage.saveIndex(projects) }
        return value
    }

    func update(_ project: ColoringProject) {
        if let index = projects.firstIndex(where: { $0.id == project.id }) { projects[index] = project } else { projects.append(project) }
    }

    func flushActiveEditor() { activeEditor?.flushSave() }
}
