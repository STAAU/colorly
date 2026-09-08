import SwiftUI

struct AppRootView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    var body: some View {
        @Bindable var model = model
        MainTabView()
            .onChange(of: scenePhase) { _, phase in
                if phase != .active { model.flushActiveEditor() }
                else { Task { await model.subscriptions.refreshCustomerInfo() } }
            }
            .sheet(isPresented: $model.showsPaywall) { PremiumPaywallView() }
    }
}
