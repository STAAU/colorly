import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var resume: ColoringProject?
    var body: some View {
        NavigationStack {
            ScrollView { VStack(alignment: .leading, spacing: 28) {
                pageRow("Featured", model.content.pages.filter(\.isFeatured))
                VStack(alignment: .leading) { Text("Categories").font(.title2.bold()).padding(.horizontal); ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(model.content.categories) { category in NavigationLink(value: category) { VStack { Image(systemName: category.symbol).font(.title); Text(category.title).font(.caption.bold()) }.frame(width: 100, height: 82).background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16)) }.buttonStyle(.plain) } }.padding(.horizontal) } }
                projectRow
                if model.favorites.isEmpty { ContentUnavailableView("Save favorite pages with the heart.", systemImage: "heart") } else { pageRow("Favorites", model.content.pages.filter { model.favorites.contains($0.id) }) }
            }.padding(.vertical) }.navigationTitle("Color & Smile")
            .navigationDestination(for: ColoringPage.self) { ColoringPagePreviewView(page: $0) }.navigationDestination(for: ColoringCategory.self) { CategoryView(category: $0) }
        }.fullScreenCover(item: $resume) { project in if let page = model.content.page(id: project.pageID) { EditorLoaderView(page: page, project: project) } }
    }
    private func pageRow(_ title: String, _ pages: [ColoringPage]) -> some View { VStack(alignment: .leading) { Text(title).font(.title2.bold()).padding(.horizontal); ScrollView(.horizontal, showsIndicators: false) { HStack(spacing: 16) { ForEach(pages) { page in ColoringPageCard(page: page).frame(width: 190) } }.padding(.horizontal) } } }
    @ViewBuilder private var projectRow: some View { let values = model.projects.filter { $0.status == .inProgress }.sorted { $0.updatedAt > $1.updatedAt }.prefix(6); if !values.isEmpty { VStack(alignment: .leading) { Text("Continue Coloring").font(.title2.bold()).padding(.horizontal); ScrollView(.horizontal, showsIndicators: false) { HStack { ForEach(Array(values)) { p in Button { resume = p } label: { ProjectCard(project: p).frame(width: 190) }.buttonStyle(.plain) } }.padding(.horizontal) } } } }
}
