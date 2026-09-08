import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var resume: ColoringProject?

    private var featured: ColoringPage? { model.content.pages.first(where: \.isFeatured) ?? model.content.pages.first }
    private var activeProjects: [ColoringProject] { Array(model.projects.filter { $0.status == .inProgress }.sorted { $0.updatedAt > $1.updatedAt }.prefix(6)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 34) {
                    EditorialHeader(eyebrow: "Your creative space", title: "Color something wonderful")
                    if let featured { hero(featured) }
                    continueSection
                    categorySection
                    favoriteSection
                }
                .padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 24).frame(maxWidth: 1100)
                .frame(maxWidth: .infinity)
            }
            .background(Color.artPaper)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: ColoringPage.self) { ColoringPagePreviewView(page: $0) }
            .navigationDestination(for: ColoringCategory.self) { CategoryView(category: $0) }
        }
        .fullScreenCover(item: $resume) { project in
            if let page = model.content.page(id: project.pageID) { EditorLoaderView(page: page, project: project) }
        }
    }

    private func hero(_ page: ColoringPage) -> some View {
        NavigationLink(value: page) {
            ZStack(alignment: .bottomLeading) {
                Image(uiImage: model.artwork.thumbnail(for: page, size: 800)).resizable().scaledToFit()
                    .frame(maxWidth: .infinity).background(.white)
                LinearGradient(colors: [.clear, .black.opacity(0.68)], startPoint: .center, endPoint: .bottom)
                VStack(alignment: .leading, spacing: 9) {
                    Text("EDITOR'S PICK").font(.caption.bold()).tracking(1.3)
                    Text(page.title).font(.title.bold())
                    Label(model.project(for: page.id) == nil ? "Start coloring" : "Continue coloring", systemImage: "paintbrush.fill")
                        .font(.headline).padding(.horizontal, 16).padding(.vertical, 11).background(.white, in: Capsule()).foregroundStyle(Color.artInk)
                }.foregroundStyle(.white).padding(22)
            }
            .aspectRatio(1.35, contentMode: .fit).clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
            .shadow(color: Color.artLavender.opacity(0.2), radius: 20, y: 10)
        }.buttonStyle(PressScaleStyle())
    }

    @ViewBuilder private var continueSection: some View {
        if !activeProjects.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                ArtSectionTitle("Continue creating", detail: "Your latest works")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(activeProjects) { project in
                            Button { resume = project } label: { ProjectCard(project: project, showsProgress: true).frame(width: 260) }
                                .buttonStyle(PressScaleStyle())
                        }
                    }.padding(.vertical, 4)
                }.contentMargins(.horizontal, 0)
            }
        }
    }

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            ArtSectionTitle("Explore worlds")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 14)], spacing: 14) {
                ForEach(model.content.categories) { category in CategoryTile(category: category) }
            }
        }
    }

    @ViewBuilder private var favoriteSection: some View {
        if !model.favorites.isEmpty {
            VStack(alignment: .leading, spacing: 14) {
                ArtSectionTitle("Loved by you")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) { ForEach(model.content.pages.filter { model.favorites.contains($0.id) }) { ColoringPageCard(page: $0).frame(width: 230) } }
                }
            }
        }
    }
}

struct CategoryTile: View {
    @Environment(AppModel.self) private var model
    let category: ColoringCategory
    private var page: ColoringPage? { model.content.pages.first { $0.categoryID == category.id } }
    var body: some View {
        NavigationLink(value: category) {
            ZStack(alignment: .bottomLeading) {
                Group {
                    if let page { Image(uiImage: model.artwork.thumbnail(for: page)).resizable().scaledToFill() }
                    else { Color.artSky.opacity(0.3) }
                }
                LinearGradient(colors: [.clear, .black.opacity(0.62)], startPoint: .top, endPoint: .bottom)
                Label(category.title, systemImage: category.symbol).font(.headline).foregroundStyle(.white).padding(14)
            }.frame(height: 160).clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }.buttonStyle(PressScaleStyle())
    }
}
