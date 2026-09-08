import SwiftUI

struct ColoringPageCard: View {
    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let page: ColoringPage

    var body: some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: page) {
                VStack(alignment: .leading, spacing: 10) {
                    Image(uiImage: model.artwork.thumbnail(for: page)).resizable().scaledToFit().frame(maxWidth: .infinity)
                        .background(.white).clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(alignment: .topLeading) {
                            if page.isPremium { Text("PLUS").font(.caption2.bold()).tracking(1).padding(.horizontal, 9).padding(.vertical, 6).background(Color.artInk, in: Capsule()).foregroundStyle(.white).padding(10) }
                        }
                    HStack(alignment: .firstTextBaseline) {
                        Text(page.title).font(.headline).foregroundStyle(Color.artInk).lineLimit(1)
                        Spacer()
                        Text(page.difficulty.rawValue).font(.caption).foregroundStyle(.secondary)
                    }
                }.contentShape(Rectangle())
            }.buttonStyle(PressScaleStyle()).accessibilityLabel("Open \(page.title)")

            Button { model.toggleFavorite(page.id) } label: {
                Image(systemName: model.favorites.contains(page.id) ? "heart.fill" : "heart")
                    .font(.system(size: 17, weight: .semibold)).frame(width: 42, height: 42)
                    .background(.regularMaterial, in: Circle()).foregroundStyle(Color.artCoral)
                    .symbolEffect(.bounce, value: model.favorites.contains(page.id))
            }.buttonStyle(.plain).padding(8)
            .accessibilityLabel(model.favorites.contains(page.id) ? "Remove \(page.title) from favorites" : "Favorite \(page.title)")
        }.accessibilityElement(children: .contain)
    }
}
