import SwiftUI

struct CategoryView: View {
    @Environment(AppModel.self) private var model
    let category: ColoringCategory
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("A world of \(category.title.lowercased()) waiting for your colors.").font(.title3).foregroundStyle(.secondary)
                PageGrid(pages: model.content.pages.filter { $0.categoryID == category.id }, minimumWidth: 210)
            }.padding(20).frame(maxWidth: 1100)
        }.background(Color.artPaper).navigationTitle(category.title)
    }
}

struct PageGrid: View {
    let pages: [ColoringPage]
    var minimumWidth: CGFloat = 180
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 330), spacing: 18)], spacing: 24) {
            ForEach(pages) { ColoringPageCard(page: $0) }
        }
    }
}
