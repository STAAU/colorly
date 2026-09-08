import RevenueCat
import SwiftUI

struct PremiumPaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selection: String?
    @State private var legalDocument: LegalDocument?
    private var subscriptions: SubscriptionManager { model.subscriptions }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    artwork
                    VStack(spacing: 8) {
                        Text("A bigger world to color").font(.largeTitle.bold()).multilineTextAlignment(.center)
                        Text(model.paywallContext ?? "Unlock every premium coloring page and support more creative adventures.").foregroundStyle(.secondary).multilineTextAlignment(.center)
                    }
                    benefits
                    plans
                    if let message = subscriptions.message { Text(message).font(.subheadline).multilineTextAlignment(.center).foregroundStyle(.secondary).padding(.horizontal) }
                    Button("Restore Purchases") { Task { await subscriptions.restore() } }.disabled(subscriptions.isPurchasing)
                    HStack {
                        Button("Privacy Policy") { legalDocument = .privacy }
                        Text("•").foregroundStyle(.secondary)
                        Button("Terms of Use") { legalDocument = .terms }
                    }.font(.footnote)
                    Text("Payment is charged to your Apple Account. Subscriptions renew automatically unless canceled at least 24 hours before the current period ends. Manage or cancel in Apple subscription settings.")
                        .font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
                }.padding(20).frame(maxWidth: 680)
            }.background(Color.artPaper)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Close") { dismiss() } } }
            .sheet(item: $legalDocument) { LegalView(document: $0) }
            .task { if subscriptions.offering == nil { await subscriptions.loadOffering() }; selection = selection ?? subscriptions.packages.first?.identifier }
            .onChange(of: subscriptions.access) { _, access in if access == .premium { dismiss() } }
        }
    }

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 34).fill(Color.artLavender.opacity(0.18))
            HStack(spacing: -28) {
                ForEach(Array(model.content.pages.filter(\.isPremium).prefix(3).enumerated()), id: \.element.id) { index, page in
                    Image(uiImage: model.artwork.thumbnail(for: page, size: 360)).resizable().scaledToFit().background(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20)).rotationEffect(.degrees(Double(index - 1) * 7)).shadow(radius: 8, y: 5)
                }
            }.padding(24)
        }.frame(height: 245)
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 13) {
            Label("Every premium curated page", systemImage: "sparkles")
            Label("New creative collections as they arrive", systemImage: "rectangle.stack.fill")
            Label("Keep all of your existing creations", systemImage: "heart.fill")
        }.font(.headline).frame(maxWidth: .infinity, alignment: .leading).padding(20).background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 24))
    }

    @ViewBuilder private var plans: some View {
        if subscriptions.packages.isEmpty {
            VStack(spacing: 12) {
                ProgressView()
                Text("Loading subscription choices…").foregroundStyle(.secondary)
                Button("Retry") { Task { await subscriptions.loadOffering() } }
            }.padding()
        } else {
            VStack(spacing: 12) {
                ForEach(subscriptions.packages, id: \.identifier) { package in
                    Button { selection = package.identifier } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(package.packageType == .annual ? "Yearly" : "Monthly").font(.headline)
                                Text(package.storeProduct.localizedPriceString).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if package.packageType == .annual { Text("BEST VALUE").font(.caption2.weight(.heavy)).tracking(0.3).foregroundStyle(.white).padding(.horizontal, 9).padding(.vertical, 5).background(Color.artCoral, in: Capsule()) }
                            Image(systemName: selection == package.identifier ? "checkmark.circle.fill" : "circle").font(.title2)
                        }.padding(17).background(selection == package.identifier ? Color.artLavender.opacity(0.16) : .white.opacity(0.7), in: RoundedRectangle(cornerRadius: 20))
                    }.buttonStyle(.plain)
                }
                Button {
                    guard let package = subscriptions.packages.first(where: { $0.identifier == selection }) else { return }
                    Task { await subscriptions.purchase(package) }
                } label: {
                    Group { if subscriptions.isPurchasing { ProgressView().tint(.white) } else { Text("Continue").font(.headline) } }
                        .frame(maxWidth: .infinity).padding(.vertical, 16).background(Color.artInk, in: Capsule()).foregroundStyle(.white)
                }.disabled(selection == nil || subscriptions.isPurchasing)
            }
        }
    }
}

enum LegalDocument: String, Identifiable { case privacy, terms; var id: String { rawValue } }
private struct LegalView: View {
    let document: LegalDocument
    @Environment(\.dismiss) private var dismiss
    var body: some View { NavigationStack { ScrollView { Text(document == .privacy ? "Privacy Policy\n\nYour coloring projects and fixture-generated artwork are stored locally. Subscription purchases are processed by Apple and RevenueCat. Anonymous account services are provided by Supabase. We do not sell personal information." : "Terms of Use\n\nPremium is an auto-renewing subscription managed through your Apple Account. Features remain available while the premium entitlement is active. Existing projects and creations remain yours to revisit. Apple’s standard Licensed Application End User License Agreement also applies.").padding() }.navigationTitle(document == .privacy ? "Privacy Policy" : "Terms of Use").toolbar { Button("Done") { dismiss() } } } }
}
