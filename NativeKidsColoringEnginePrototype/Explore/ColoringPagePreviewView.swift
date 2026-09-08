import SwiftUI

struct ColoringPagePreviewView: View {
    @Environment(AppModel.self) private var model
    let page: ColoringPage
    @State private var editorProject: ColoringProject?
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(uiImage: model.artwork.thumbnail(for: page, size: 700)).resizable().scaledToFit().background(.white).clipShape(RoundedRectangle(cornerRadius: 24))
                HStack { Text(page.difficulty.rawValue).foregroundStyle(.secondary); Spacer(); Button { model.toggleFavorite(page.id) } label: { Label(model.favorites.contains(page.id) ? "Favorited" : "Favorite", systemImage: model.favorites.contains(page.id) ? "heart.fill" : "heart") } }
                Button { editorProject = model.makeProject(for: page) } label: { Text(model.project(for: page.id) == nil ? "Start Coloring" : "Continue Coloring").frame(maxWidth: .infinity).padding().font(.headline) }.buttonStyle(.borderedProminent).controlSize(.large)
            }.padding().frame(maxWidth: 700)
        }.navigationTitle(page.title)
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
            let vm = ColoringViewModel(asset: model.artwork.asset(for: page), project: project, restoredPaint: paint, appModel: model)
            viewModel = vm; model.activeEditor = vm
        }.onDisappear { model.activeEditor = nil }
    }
}
