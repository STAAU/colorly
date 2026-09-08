import SwiftUI

struct GalleryView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: ColoringProject?
    var body: some View {
        NavigationStack {
            ScrollView {
                if model.projects.isEmpty { ContentUnavailableView("Your colorful creations will appear here.", systemImage: "photo.on.rectangle.angled") }
                else { section("In Progress", .inProgress); section("Finished", .finished) }
            }.navigationTitle("Gallery")
        }.fullScreenCover(item: $selected) { project in if let page = model.content.page(id: project.pageID) { EditorLoaderView(page: page, project: project) } }
    }
    @ViewBuilder private func section(_ title: String, _ status: ProjectStatus) -> some View {
        let values = model.projects.filter { $0.status == status }.sorted { $0.updatedAt > $1.updatedAt }
        if !values.isEmpty {
            VStack(alignment: .leading) { Text(title).font(.title2.bold()).padding(.horizontal); LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 230), spacing: 16)]) { ForEach(values) { project in Button { selected = project } label: { ProjectCard(project: project) }.buttonStyle(.plain) } }.padding(.horizontal) }.padding(.vertical)
        }
    }
}
