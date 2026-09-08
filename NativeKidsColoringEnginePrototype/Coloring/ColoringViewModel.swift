import Foundation
import Observation

@MainActor
@Observable
final class ColoringViewModel {
    enum SaveAlert: Identifiable {
        case success
        case denied
        case restricted
        case failed

        var id: String {
            switch self {
            case .success: "success"
            case .denied: "denied"
            case .restricted: "restricted"
            case .failed: "failed"
            }
        }

        var title: String {
            switch self {
            case .success: "Saved to Photos"
            case .denied: "Photos Access Is Off"
            case .restricted: "Photos Are Restricted"
            case .failed: "Couldn’t Save"
            }
        }

        var message: String {
            switch self {
            case .success:
                "Your finished cat was added to Photos."
            case .denied:
                "Allow Add Photos access in Settings, then try saving again."
            case .restricted:
                "This device does not currently allow adding pictures to Photos."
            case .failed:
                "The picture could not be saved. Please check available storage and try again."
            }
        }
    }

    let document: ColoringDocument

    var selectedTool: ColoringTool = .fill
    var selectedColor: PaletteColor = PaletteColor.all[0]
    var brushSize: BrushSize = .medium
    var isPreparingRegions = true
    var isSaving = false
    var canUndo = false
    var canRedo = false
    var isResetConfirmationPresented = false
    var saveAlert: SaveAlert?

    @ObservationIgnored private let photoSaveService = PhotoSaveService()

    init() {
        let lineArt = SampleCatPageRenderer.render()
        let page = ColoringPage(
            id: "phase-zero-cat",
            title: "Cat",
            pixelSize: SampleCatPageRenderer.canvasSize,
            lineArt: lineArt
        )
        document = ColoringDocument(page: page)
        document.onHistoryChange = { [weak self] in
            self?.refreshHistoryState()
        }

        let mask = BoundaryMaskBuilder.build(from: lineArt, width: page.width, height: page.height)
        Task { [weak self] in
            let segmentation = await Task.detached(priority: .userInitiated) {
                FloodFillEngine.segment(mask: mask)
            }.value
            guard !Task.isCancelled, let self else { return }
            document.install(segmentation: segmentation)
            isPreparingRegions = false
        }
    }

    func refreshHistoryState() {
        canUndo = document.canUndo
        canRedo = document.canRedo
    }

    func undo() {
        document.undo()
        refreshHistoryState()
    }

    func redo() {
        document.redo()
        refreshHistoryState()
    }

    func confirmReset() {
        document.reset()
        refreshHistoryState()
    }

    func save() {
        guard !isSaving, let pngData = document.flattenedPNGData() else {
            if !isSaving { saveAlert = .failed }
            return
        }
        isSaving = true
        Task { [weak self, photoSaveService] in
            do {
                try await photoSaveService.savePNG(pngData)
                guard let self else { return }
                isSaving = false
                saveAlert = .success
            } catch PhotoSaveError.permissionDenied {
                guard let self else { return }
                isSaving = false
                saveAlert = .denied
            } catch PhotoSaveError.permissionRestricted {
                guard let self else { return }
                isSaving = false
                saveAlert = .restricted
            } catch {
                guard let self else { return }
                isSaving = false
                saveAlert = .failed
            }
        }
    }
}
