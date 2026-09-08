import SwiftUI

struct CategoryView: View {
    @Environment(AppModel.self) private var model
    let category: ColoringCategory
    var body: some View {
        ScrollView { PageGrid(pages: model.content.pages.filter { $0.categoryID == category.id }) }.navigationTitle(category.title)
    }
}

struct PageGrid: View {
    let pages: [ColoringPage]
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 230), spacing: 16)], spacing: 20) {
            ForEach(pages) { page in ColoringPageCard(page: page) }
        }.padding()
    }
}
