import SwiftUI

struct ProjectCard: View {
    @Environment(AppModel.self) private var model
    let project: ColoringProject
    @State private var image: UIImage?
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group { if let image { Image(uiImage: image).resizable().scaledToFit() } else if let page = model.content.page(id: project.pageID) { Image(uiImage: model.artwork.thumbnail(for: page)).resizable().scaledToFit() } }.background(.white).clipShape(RoundedRectangle(cornerRadius: 18))
            Text(model.content.page(id: project.pageID)?.title ?? "Coloring").font(.headline)
            Text(project.updatedAt, format: .relative(presentation: .named)).font(.caption).foregroundStyle(.secondary)
        }.task { if let data = await model.storage.thumbnail(for: project) { image = UIImage(data: data) } }
        .accessibilityLabel("\(model.content.page(id: project.pageID)?.title ?? "Coloring"), \(project.status == .finished ? "Finished" : "In Progress")")
    }
}
