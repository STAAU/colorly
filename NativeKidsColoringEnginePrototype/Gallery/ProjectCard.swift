import SwiftUI

struct ProjectCard: View {
    @Environment(AppModel.self) private var model
    let project: ColoringProject
    var showsProgress = false
    @State private var image: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Group {
                if let image { Image(uiImage: image).resizable().scaledToFit() }
                else if let page = model.content.page(id: project.pageID) { Image(uiImage: model.artwork.thumbnail(for: page)).resizable().scaledToFit() }
            }
            .frame(maxWidth: .infinity).background(.white).clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(alignment: .bottom) {
                if showsProgress { ProgressView(value: project.status == .finished ? 1 : 0.58).tint(Color.artCoral).padding(.horizontal, 14).offset(y: 3) }
            }
            HStack(alignment: .firstTextBaseline) {
                Text(model.content.page(id: project.pageID)?.title ?? "Coloring").font(.headline).foregroundStyle(Color.artInk).lineLimit(1)
                Spacer()
                Text(project.updatedAt, format: .relative(presentation: .named)).font(.caption).foregroundStyle(.secondary).lineLimit(1)
            }
        }
        .task { if let data = await model.storage.thumbnail(for: project) { image = UIImage(data: data) } }
        .accessibilityLabel("\(model.content.page(id: project.pageID)?.title ?? "Coloring"), \(project.status == .finished ? "Finished" : "In Progress")")
    }
}
