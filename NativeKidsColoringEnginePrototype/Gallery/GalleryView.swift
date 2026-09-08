import SwiftUI

struct GalleryView: View {
    @Environment(AppModel.self) private var model
    @State private var selected: ColoringProject?
    @State private var generatedSelection: GeneratedPageRecord?
    @State private var deleteCandidate: GeneratedPageRecord?
    @State private var photoSelection: PhotoGenerationRecord?
    @State private var photoDeleteCandidate: PhotoGenerationRecord?
    private var visiblePhotos:[PhotoGenerationRecord] { model.photoHistory.filter{$0.status == .completed && !$0.isHiddenFromGallery} }
    private var visibleGenerations: [GeneratedPageRecord] {
        model.generatedHistory.filter { $0.status == .completed && !$0.isHiddenFromGallery }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 30) {
                    EditorialHeader(eyebrow: "Personal collection", title: "Your gallery")
                    photoSection
                    generatedSection
                    if model.projects.isEmpty && visibleGenerations.isEmpty && visiblePhotos.isEmpty { emptyState } else {
                        section("Works in progress", .inProgress)
                        section("Finished pieces", .finished)
                    }
                }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 24).frame(maxWidth: 1100).frame(maxWidth: .infinity)
            }.background(Color.artPaper).toolbar(.hidden, for: .navigationBar)
        }.fullScreenCover(item: $selected) { project in
            if let page = model.page(id: project.pageID) { EditorLoaderView(page: page, project: project) }
        }
        .sheet(item: $generatedSelection) { record in GeneratedResultView(record: record) }
        .sheet(item:$photoSelection){PhotoResultView(record:$0)}
        .confirmationDialog("Delete this photo creation?",isPresented:Binding(get:{photoDeleteCandidate != nil},set:{if !$0{photoDeleteCandidate=nil}}),titleVisibility:.visible){Button("Delete Creation",role:.destructive){if let value=photoDeleteCandidate{model.delete(value)};photoDeleteCandidate=nil};Button("Cancel",role:.cancel){photoDeleteCandidate=nil}}message:{Text("Its coloring project, if any, will remain available offline.")}
        .confirmationDialog("Delete this AI creation?", isPresented: Binding(get: { deleteCandidate != nil }, set: { if !$0 { deleteCandidate=nil } }), titleVisibility: .visible) {
            Button("Delete Creation", role: .destructive) { if let value=deleteCandidate { model.delete(value) }; deleteCandidate=nil }
            Button("Cancel", role: .cancel) { deleteCandidate=nil }
        } message: { Text("Its saved coloring project, if any, will remain available.") }
    }

    @ViewBuilder private var photoSection:some View { if !visiblePhotos.isEmpty{VStack(alignment:.leading,spacing:14){ArtSectionTitle("Photo Creations",detail:"\(visiblePhotos.count)");LazyVGrid(columns:[GridItem(.adaptive(minimum:160,maximum:260),spacing:18)],spacing:22){ForEach(visiblePhotos){record in PhotoCreationCard(record:record).contentShape(Rectangle()).onTapGesture{photoSelection=record}.contextMenu{Button("Delete",role:.destructive){photoDeleteCandidate=record}}}}}} }

    @ViewBuilder private var generatedSection: some View {
        let records = visibleGenerations
        if !records.isEmpty { VStack(alignment:.leading,spacing:14){ArtSectionTitle("AI Creations",detail:"\(records.count)"); LazyVGrid(columns:[GridItem(.adaptive(minimum:160,maximum:260),spacing:18)],spacing:22){ForEach(records){record in GeneratedCreationCard(record:record).contentShape(Rectangle()).onTapGesture{generatedSelection=record}.contextMenu{Button("Delete",role:.destructive){deleteCandidate=record}}}}} }
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
