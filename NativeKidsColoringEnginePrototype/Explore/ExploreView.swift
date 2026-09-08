import SwiftUI

struct ExploreView: View {
    @Environment(AppModel.self) private var model
    @State private var search = ""
    @State private var difficulty: ColoringDifficulty?
    private var results: [ColoringPage] { model.content.pages.filter { page in
        (search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || page.title.localizedCaseInsensitiveContains(search.trimmingCharacters(in: .whitespacesAndNewlines))) && (difficulty == nil || page.difficulty == difficulty)
    }}
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Categories").font(.title2.bold()).padding(.horizontal)
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 145), spacing: 12)], spacing: 12) {
                        ForEach(model.content.categories) { category in
                            NavigationLink(value: category) {
                                HStack(spacing: 12) {
                                    Image(systemName: category.symbol).font(.title2).frame(width: 32)
                                    Text(category.title).font(.headline)
                                    Spacer()
                                }
                                .padding().frame(minHeight: 68)
                                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                            }.buttonStyle(.plain)
                        }
                    }.padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) { HStack { filter("All", nil); ForEach(ColoringDifficulty.allCases) { value in filter(value.rawValue, value) } }.padding(.horizontal) }
                    if results.isEmpty { ContentUnavailableView("No coloring pages found.", systemImage: "magnifyingglass") } else { PageGrid(pages: results) }
                }
            }.navigationTitle("Explore").searchable(text: $search, prompt: "Search coloring pages")
            .toolbar { Menu("Categories", systemImage: "square.grid.2x2") { ForEach(model.content.categories) { category in NavigationLink(category.title, value: category) } } }
            .navigationDestination(for: ColoringPage.self) { ColoringPagePreviewView(page: $0) }
            .navigationDestination(for: ColoringCategory.self) { CategoryView(category: $0) }
        }
    }
    private func filter(_ title: String, _ value: ColoringDifficulty?) -> some View { Button(title) { difficulty = value }.buttonStyle(.borderedProminent).tint(difficulty == value ? .blue : .gray) }
}
