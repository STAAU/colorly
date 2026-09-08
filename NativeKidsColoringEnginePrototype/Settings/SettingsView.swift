import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    private var subscriptions: SubscriptionManager { model.subscriptions }

    var body: some View {
        NavigationStack {
            List {
                Section("Premium") {
                    HStack {
                        Label("Membership", systemImage: "sparkles")
                        Spacer()
                        Text(subscriptions.access.hasPremium ? "Premium" : subscriptions.access == .loading ? "Checking…" : "Free").foregroundStyle(.secondary)
                    }
                    if subscriptions.access.hasPremium {
                        Button("Manage Subscription") { subscriptions.manageSubscriptions() }
                    } else {
                        Button("Explore Premium") { dismiss(); model.presentPaywall(context: "Unlock all premium coloring pages whenever inspiration strikes.") }
                    }
                    Button("Restore Purchases") { Task { await subscriptions.restore() } }.disabled(subscriptions.isPurchasing)
                    if let message = subscriptions.message { Text(message).font(.footnote).foregroundStyle(.secondary) }
                }
                Section("Help & Legal") {
                    Link("Privacy Policy", destination: URL(string: "https://superappp.com/privacy")!)
                    Link("Terms of Use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                    Link("Contact Support", destination: URL(string: "mailto:support@superappp.com")!)
                }
                Section("About") {
                    LabeledContent("Storage", value: "On this device")
                    LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
            .navigationTitle("Settings")
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }
}
