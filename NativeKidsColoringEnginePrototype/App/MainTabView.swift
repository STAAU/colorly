import SwiftUI

struct MainTabView: View {
    @Environment(AppModel.self) private var model
    var body: some View { @Bindable var model = model
        TabView(selection: $model.selectedTab) {
            HomeView().tabItem { Label("Home", systemImage: "house.fill") }.tag(0)
            ExploreView().tabItem { Label("Explore", systemImage: "square.grid.2x2.fill") }.tag(1)
            GalleryView().tabItem { Label("Gallery", systemImage: "photo.stack.fill") }.tag(2)
        }.tint(.blue)
    }
}
