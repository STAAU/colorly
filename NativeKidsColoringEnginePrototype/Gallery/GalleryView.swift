import SwiftUI

struct GalleryView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: ColoringProject?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    EditorialHeader(eyebrow: "Personal collection", title: "Your gallery")
                    if model.projects.isEmpty { emptyState } else {
                        section("Works in progress", .inProgress)
                        section("Finished pieces", .finished)
                    }
                }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 24).frame(maxWidth: 1100).frame(maxWidth: .infinity)
            }.background(Color.artPaper).toolbar(.hidden, for: .navigationBar)
        }.fullScreenCover(item: $selected) { project in
            if let page = model.content.page(id: project.pageID) { EditorLoaderView(page: page, project: project) }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 30).fill(Color.artLavender.opacity(0.14)).frame(width: 180, height: 180).rotationEffect(.degrees(-5))
                Image(systemName: "paintbrush.pointed.fill").font(.system(size: 64)).foregroundStyle(Color.artLavender)
            }
            Text("A gallery all your own").font(.title2.bold())
            Text("Start coloring a page and your artwork will be collected here.").multilineTextAlignment(.center).foregroundStyle(.secondary).frame(maxWidth: 380)
            Button { model.selectedTab = 1 } label: { Label("Explore artwork", systemImage: "sparkles").font(.headline).padding(.horizontal, 20).padding(.vertical, 13).background(Color.artInk, in: Capsule()).foregroundStyle(.white) }
                .buttonStyle(PressScaleStyle())
        }.frame(maxWidth: .infinity).padding(.vertical, 50)
    }

    @ViewBuilder private func section(_ title: String, _ status: ProjectStatus) -> some View {
        let values = model.projects.filter { $0.status == status }.sorted { $0.updatedAt > $1.updatedAt }
        if !values.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                ArtSectionTitle(title, detail: "\(values.count)")
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 210, maximum: 340), spacing: 20)], spacing: 26) {
                    ForEach(values) { project in Button { selected = project } label: { ProjectCard(project: project, showsProgress: status == .inProgress) }.buttonStyle(PressScaleStyle()) }
                }
            }
        }
    }
}
