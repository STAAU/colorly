import SwiftUI

struct ColoringPageCard: View {
    @Environment(AppModel.self) private var model
    let page: ColoringPage

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: page) {
                VStack(alignment: .leading, spacing: 8) {
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: model.artwork.thumbnail(for: page))
                            .resizable().scaledToFit().background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        if page.isPremium {
                            Text("PLUS").font(.caption2.bold()).padding(6)
                                .background(.blue, in: Capsule()).foregroundStyle(.white).padding(6)
                        }
                    }
                    Text(page.title).font(.headline).lineLimit(1)
                    Text(page.difficulty.rawValue).font(.caption).foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open \(page.title)")

            Button { model.toggleFavorite(page.id) } label: {
                Image(systemName: model.favorites.contains(page.id) ? "heart.fill" : "heart")
                    .frame(width: 44, height: 44).background(.thinMaterial, in: Circle()).foregroundStyle(.pink)
            }
            .buttonStyle(.plain)
            .padding(6)
            .accessibilityLabel(model.favorites.contains(page.id) ? "Remove \(page.title) from favorites" : "Favorite \(page.title)")
        }
        .accessibilityElement(children: .contain)
    }
}
