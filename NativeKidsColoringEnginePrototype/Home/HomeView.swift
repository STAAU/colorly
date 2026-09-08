import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var model
    @State private var resume: ColoringProject?
    @State private var showsCreate = false
    @State private var showsPhotoCreate = false
    @State private var showsSettings = false

    private var featured: ColoringPage? { model.content.pages.first(where: \.isFeatured) ?? model.content.pages.first }
    private var activeProjects: [ColoringProject] { Array(model.projects.filter { $0.status == .inProgress }.sorted { $0.updatedAt > $1.updatedAt }.prefix(6)) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    HStack {
                        Text("colorly").font(.title3.weight(.heavy)).foregroundStyle(Color.artInk)
                        Spacer()
                        HStack(spacing: 8) {
                            Button { model.presentPaywall(context: "Discover every premium page in the collection.") } label: { Image(systemName: model.subscriptions.access.hasPremium ? "sparkles" : "crown.fill").font(.system(size: 15, weight: .semibold)).frame(width: 38, height: 38).foregroundStyle(Color.artLavender).background(Color.artLavender.opacity(0.16), in: Circle()) }.accessibilityLabel("Premium")
                            Button { showsSettings = true } label: { Image(systemName: "gearshape.fill").font(.system(size: 15, weight: .semibold)).frame(width: 38, height: 38).foregroundStyle(Color.artInk).background(Color.primary.opacity(0.06), in: Circle()) }.accessibilityLabel("Settings")
                        }
                    }
                    EditorialHeader(eyebrow: "Your creative space", title: "Color something new.")
                    createHero
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
            if let page = model.page(id: project.pageID) { EditorLoaderView(page: page, project: project) }
        }
        .sheet(isPresented: $showsCreate) { CreateView() }
        .sheet(isPresented: $showsPhotoCreate) { PhotoCreateView() }
        .sheet(isPresented: $showsSettings) { SettingsView() }
    }

    private var createHero: some View {
        HStack(spacing: 14) {
            creationAction("Describe with AI", "wand.and.stars", Color.artLavender) { showsCreate = true }
            creationAction("Use a Photo", "camera.fill", Color.artCoral) { showsPhotoCreate = true }
        }
    }
    private func creationAction(_ title:String,_ symbol:String,_ color:Color,action:@escaping()->Void)->some View {
        Button(action:action){VStack(alignment:.leading,spacing:16){Image(systemName:symbol).font(.system(size:30,weight:.semibold));Text(title).font(.title3.bold()).multilineTextAlignment(.leading);Image(systemName:"arrow.right.circle.fill").font(.title2)}.frame(maxWidth:.infinity,alignment:.leading).padding(20).foregroundStyle(.white).background(color,in:RoundedRectangle(cornerRadius:26))}.buttonStyle(PressScaleStyle())
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
