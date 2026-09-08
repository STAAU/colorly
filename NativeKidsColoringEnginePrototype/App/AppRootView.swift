import SwiftUI

struct AppRootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    var body: some View { MainTabView().onChange(of: scenePhase) { _, phase in if phase != .active { model.flushActiveEditor() } } }
}
