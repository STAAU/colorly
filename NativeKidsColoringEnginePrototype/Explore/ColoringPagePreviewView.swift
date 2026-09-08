import SwiftUI

struct ColoringPagePreviewView: View {
    @Environment(AppModel.self) private var model
    let page: ColoringPage
    @State private var editorProject: ColoringProject?

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Image(uiImage: model.artwork.thumbnail(for: page, size: 800)).resizable().scaledToFit().background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous)).shadow(color: .black.opacity(0.08), radius: 20, y: 8)
                HStack {
                    VStack(alignment: .leading, spacing: 4) { Text(page.title).font(.title.bold()); Text(page.difficulty.rawValue).foregroundStyle(.secondary) }
                    Spacer()
                    Button { model.toggleFavorite(page.id) } label: {
                        Image(systemName: model.favorites.contains(page.id) ? "heart.fill" : "heart").font(.title3).frame(width: 48, height: 48).background(.regularMaterial, in: Circle()).foregroundStyle(Color.artCoral)
                    }.buttonStyle(PressScaleStyle()).accessibilityLabel(model.favorites.contains(page.id) ? "Remove favorite" : "Favorite")
                }
                Button {
                    if model.canStart(page) { editorProject = model.makeProject(for: page) }
                    else { model.presentPaywall(context: "Unlock \(page.title) and every premium coloring page.") }
                } label: {
                    Label(model.project(for: page.id) == nil ? (model.canStart(page) ? "Start coloring" : "Unlock with Premium") : "Continue coloring", systemImage: model.canStart(page) ? "paintbrush.fill" : "lock.fill")
                        .font(.headline).frame(maxWidth: .infinity).padding(.vertical, 15).background(Color.artInk, in: Capsule()).foregroundStyle(.white)
                }.buttonStyle(PressScaleStyle())
            }.padding(20).frame(maxWidth: 760)
        }.background(Color.artPaper).navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $editorProject) { project in EditorLoaderView(page: page, project: project) }
    }
}

struct EditorLoaderView: View {
    @Environment(AppModel.self) private var model
    let page: ColoringPage
    let project: ColoringProject
    @State private var viewModel: ColoringViewModel?
    var body: some View {
        NavigationStack {
            Group { if let viewModel { ColoringScreen(viewModel: viewModel) } else { ProgressView("Opening \(page.title)…") } }
        }.task {
            let paint = await model.storage.paint(for: project)
            guard viewModel == nil else { return }
            guard let asset = await model.asset(for: page, project: project) else { return }
            let vm = ColoringViewModel(asset: asset, project: project, restoredPaint: paint, appModel: model)
            viewModel = vm; model.activeEditor = vm
        }.onDisappear { model.activeEditor = nil }
    }
}
