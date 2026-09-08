import SwiftUI

struct MainTabView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            HomeView().tag(0)
            ExploreView().tag(1)
            GalleryView().tag(2)
        }
        .toolbar(.hidden, for: .tabBar)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FloatingTabBar(selection: $model.selectedTab)
        }
        .tint(.artLavender)
    }
}

private struct FloatingTabBar: View {
    @Binding var selection: Int
    private let items = [("Home", "house.fill"), ("Explore", "sparkles.rectangle.stack.fill"), ("Gallery", "photo.stack.fill")]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items.indices, id: \.self) { index in
                Button { selection = index } label: {
                    HStack(spacing: 7) {
                        Image(systemName: items[index].1).font(.system(size: 17, weight: .semibold))
                        if selection == index { Text(items[index].0).font(.subheadline.bold()).lineLimit(1) }
                    }
                    .foregroundStyle(selection == index ? .white : Color.artInk.opacity(0.65))
                    .frame(maxWidth: .infinity, minHeight: 48)
                    .background(selection == index ? Color.artInk : .clear, in: Capsule())
                    .contentShape(Capsule())
                }
                .buttonStyle(PressScaleStyle())
                .accessibilityLabel(items[index].0)
                .accessibilityAddTraits(selection == index ? .isSelected : [])
            }
        }
        .padding(6)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().stroke(.primary.opacity(0.08)))
        .shadow(color: .black.opacity(0.14), radius: 18, y: 8)
        .padding(.horizontal, 24)
        .padding(.vertical, 8)
        .frame(maxWidth: 480)
    }
}
