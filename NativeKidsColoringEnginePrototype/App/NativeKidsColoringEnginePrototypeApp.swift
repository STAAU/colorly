import SwiftUI

@main
struct NativeKidsColoringEnginePrototypeApp: App {
    @State private var model = AppModel()
    var body: some Scene { WindowGroup { AppRootView().environment(model) } }
}
