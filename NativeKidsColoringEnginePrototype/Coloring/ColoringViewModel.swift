import Foundation
import Observation

@MainActor @Observable
final class ColoringViewModel {
    enum SaveAlert: Identifiable {
        case success, denied, restricted, failed
        var id: String { title }
        var title: String { switch self { case .success: "Saved to Photos"; case .denied: "Photos Access Is Off"; case .restricted: "Photos Are Restricted"; case .failed: "Couldn’t Save" } }
        var message: String { switch self { case .success: "Your picture was added to Photos."; case .denied: "Allow Add Photos access in Settings, then try again."; case .restricted: "This device does not currently allow adding pictures to Photos."; case .failed: "The picture could not be saved. Please check available storage and try again." } }
    }

    let document: ColoringDocument
    let page: ColoringPage
    var project: ColoringProject
    var selectedTool: ColoringTool = .fill
    var selectedColor = PaletteColor.all[0]
    var brushSize: BrushSize = .medium
    var isPreparingRegions = true
    var isSaving = false
    var canUndo = false
    var canRedo = false
    var isResetConfirmationPresented = false
    var saveAlert: SaveAlert?
    @ObservationIgnored private let appModel: AppModel
    @ObservationIgnored private let photoSaveService = PhotoSaveService()
    @ObservationIgnored private var saveTask: Task<Void, Never>?

    init(asset: ColoringPageAsset, project: ColoringProject, restoredPaint: Data?, appModel: AppModel) {
        page = asset.page; self.project = project; self.appModel = appModel
        document = ColoringDocument(page: asset, restoredPaint: restoredPaint)
        document.onHistoryChange = { [weak self] in self?.refreshHistoryState() }
        let mask = BoundaryMaskBuilder.build(from: asset.lineArt, width: asset.width, height: asset.height)
        Task { [weak self] in
            let segmentation = await Task.detached(priority: .userInitiated) { FloodFillEngine.segment(mask: mask) }.value
            guard let self, !Task.isCancelled else { return }
            document.install(segmentation: segmentation); isPreparingRegions = false
        }
    }

    func refreshHistoryState() { canUndo = document.canUndo; canRedo = document.canRedo }
    func editFinished() { refreshHistoryState(); if project.status == .finished { project.status = .inProgress }; scheduleSave() }
    func undo() { document.undo(); editFinished() }
    func redo() { document.redo(); editFinished() }
    func confirmReset() { document.reset(); editFinished() }
    func scheduleSave() { saveTask?.cancel(); saveTask = Task { try? await Task.sleep(for: .milliseconds(650)); if !Task.isCancelled { persist() } } }
    func flushSave() { saveTask?.cancel(); persist() }
    func finish() { project.status = .finished; appModel.selectedTab = 2; flushSave() }

    private func persist() {
        guard let paint = document.paintPNGData(), let flattened = document.flattenedPNGData(), let thumbnail = ThumbnailService.make(from: flattened) else { return }
        project.updatedAt = Date(); appModel.update(project)
        let snapshot = appModel.projects
        Task { [storage = appModel.storage, project, paint, thumbnail] in try? await storage.save(project: project, paint: paint, thumbnail: thumbnail, allProjects: snapshot) }
    }

    func save() {
        guard !isSaving, let pngData = document.flattenedPNGData() else { if !isSaving { saveAlert = .failed }; return }
        isSaving = true
        Task { [weak self, photoSaveService] in
            do { try await photoSaveService.savePNG(pngData); self?.isSaving = false; self?.saveAlert = .success }
            catch PhotoSaveError.permissionDenied { self?.isSaving = false; self?.saveAlert = .denied }
            catch PhotoSaveError.permissionRestricted { self?.isSaving = false; self?.saveAlert = .restricted }
            catch { self?.isSaving = false; self?.saveAlert = .failed }
        }
    }
}
