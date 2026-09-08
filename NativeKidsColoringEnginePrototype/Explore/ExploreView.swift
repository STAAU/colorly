import SwiftUI

struct ExploreView: View {
    @Environment(AppModel.self) private var model
    @State private var search = ""
    @State private var difficulty: ColoringDifficulty?

    private var featured: ColoringPage? { model.content.pages.dropFirst().first(where: \.isFeatured) ?? model.content.pages.first }
    private var results: [ColoringPage] { model.content.pages.filter { page in
        (search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || page.title.localizedCaseInsensitiveContains(search.trimmingCharacters(in: .whitespacesAndNewlines))) && (difficulty == nil || page.difficulty == difficulty)
    }}

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    EditorialHeader(eyebrow: "Discover", title: "Find your next page")
                    if let featured { FeaturedExploreCard(page: featured) }
                    categories
                    filters
                    VStack(alignment: .leading, spacing: 14) {
                        ArtSectionTitle(search.isEmpty ? "All artwork" : "Search results", detail: "\(results.count) pages")
                        if results.isEmpty { emptyResults } else { PageGrid(pages: results, minimumWidth: 210) }
                    }
                }.padding(.horizontal, 20).padding(.top, 18).padding(.bottom, 24).frame(maxWidth: 1100).frame(maxWidth: .infinity)
            }
            .background(Color.artPaper).toolbar(.hidden, for: .navigationBar)
            .searchable(text: $search, prompt: "Search artwork")
            .navigationDestination(for: ColoringPage.self) { ColoringPagePreviewView(page: $0) }
            .navigationDestination(for: ColoringCategory.self) { CategoryView(category: $0) }
        }
    }

    private var categories: some View {
        VStack(alignment: .leading, spacing: 14) {
            ArtSectionTitle("Browse by world")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) { ForEach(model.content.categories) { CategoryTile(category: $0).frame(width: 190) } }
            }
        }
    }

    private var filters: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 9) {
                filter("All levels", nil)
                ForEach(ColoringDifficulty.allCases) { filter($0.rawValue, $0) }
            }
        }
    }

    private func filter(_ title: String, _ value: ColoringDifficulty?) -> some View {
        Button(title) { difficulty = value }
            .font(.subheadline.weight(.semibold)).padding(.horizontal, 15).padding(.vertical, 10)
            .foregroundStyle(difficulty == value ? .white : Color.artInk)
            .background(difficulty == value ? Color.artInk : Color.primary.opacity(0.07), in: Capsule())
            .buttonStyle(.plain).accessibilityAddTraits(difficulty == value ? .isSelected : [])
    }

    private var emptyResults: some View {
        VStack(spacing: 12) {
            Image(systemName: "paintpalette").font(.system(size: 42)).foregroundStyle(Color.artLavender)
            Text("No artwork found").font(.title3.bold())
            Text("Try another name or difficulty.").foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity).padding(.vertical, 50)
    }
}

private struct FeaturedExploreCard: View {
    @Environment(AppModel.self) private var model
    let page: ColoringPage
    var body: some View {
        NavigationLink(value: page) {
            HStack(spacing: 0) {
                Image(uiImage: model.artwork.thumbnail(for: page, size: 500)).resizable().scaledToFill().frame(maxWidth: .infinity).clipped()
                VStack(alignment: .leading, spacing: 10) {
                    Text("FEATURED").font(.caption.bold()).tracking(1.3).foregroundStyle(Color.artCoral)
                    Text(page.title).font(.title2.bold()).foregroundStyle(Color.artInk)
                    Text("A fresh canvas chosen to spark your imagination.").font(.subheadline).foregroundStyle(.secondary)
                    Image(systemName: "arrow.right.circle.fill").font(.title).foregroundStyle(Color.artLavender)
                }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            }.frame(minHeight: 220).background(Color.artLavender.opacity(0.12), in: RoundedRectangle(cornerRadius: 26)).clipShape(RoundedRectangle(cornerRadius: 26))
        }.buttonStyle(PressScaleStyle())
    }
}
