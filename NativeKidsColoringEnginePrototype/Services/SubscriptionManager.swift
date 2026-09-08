import Foundation
import Observation
import RevenueCat
import Supabase
import UIKit

enum PremiumAccessState: Equatable {
    case loading
    case free
    case premium
    case offlineCachedPremium

    var hasPremium: Bool { self == .premium || self == .offlineCachedPremium }
}

@MainActor @Observable final class SubscriptionManager {
    static let entitlementID = "premium"
    private static let revenueCatKey = "appl_iUnPTOvYvUFrKyiGMNpGtmQyDbt"
    private static let supabaseURL = URL(string: "https://mqpwhaxmeamlgydhkdnc.supabase.co")!
    private static let supabaseKey = "sb_publishable_H0jv0HAfvaQHWQTjg1z5ZA_b-_32gPd"
    private static let cachedPremiumKey = "premium.entitlement.cached"
    private static let cachedPremiumDateKey = "premium.entitlement.verifiedAt"
    private static let offlineCacheLifetime: TimeInterval = 72 * 60 * 60

    private let supabase = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    var access: PremiumAccessState = .loading
    var offering: Offering?
    var isPurchasing = false
    var message: String?
    private var configured = false

    init() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Self.cachedPremiumKey),
           let verifiedAt = defaults.object(forKey: Self.cachedPremiumDateKey) as? Date,
           Date().timeIntervalSince(verifiedAt) < Self.offlineCacheLifetime {
            access = .offlineCachedPremium
        }
        Task { await start() }
    }

    var packages: [Package] {
        guard let offering else { return [] }
        let available = offering.availablePackages.filter { $0.packageType == .annual || $0.packageType == .monthly }
        return available.sorted { lhs, rhs in lhs.packageType == .annual && rhs.packageType != .annual }
    }

    func start() async {
        guard !configured else { return }
        do {
            let userID: String
            if let session = try? await supabase.auth.session {
                userID = session.user.id.uuidString
            } else {
                userID = try await supabase.auth.signInAnonymously().user.id.uuidString
            }
            Purchases.configure(withAPIKey: Self.revenueCatKey, appUserID: userID)
            configured = true
            async let info: Void = refreshCustomerInfo()
            async let offers: Void = loadOffering()
            _ = await (info, offers)
            Task { await observeCustomerInfo() }
        } catch {
            if !access.hasPremium { access = .free }
            message = "We couldn’t connect to the store. You can keep coloring and try again later."
        }
    }

    func loadOffering() async {
        guard configured else { return }
        do {
            offering = try await Purchases.shared.offerings().current
            if offering == nil { message = "Subscriptions aren’t available right now. Please try again later." }
        } catch {
            message = "The store is taking a little longer than usual. Tap retry when you’re ready."
        }
    }

    func refreshCustomerInfo() async {
        guard configured else { return }
        do { apply(try await Purchases.shared.customerInfo()) }
        catch {
            if !access.hasPremium { access = .free }
            message = "Your latest subscription status couldn’t be checked."
        }
    }

    func purchase(_ package: Package) async {
        isPurchasing = true; message = nil
        defer { isPurchasing = false }
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { message = "No changes were made."; return }
            apply(result.customerInfo)
            if access.hasPremium { message = "Premium is ready. Have fun creating!" }
            else { message = "Your purchase is pending approval. Premium will unlock automatically." }
        } catch {
            message = "That purchase couldn’t be completed. Please try again."
        }
    }

    func restore() async {
        isPurchasing = true; message = nil
        defer { isPurchasing = false }
        do {
            apply(try await Purchases.shared.restorePurchases())
            message = access.hasPremium ? "Your Premium access has been restored." : "We didn’t find an active subscription for this account."
        } catch { message = "Restore couldn’t be completed. Check your connection and try again." }
    }

    func manageSubscriptions() {
        guard let url = URL(string: "https://apps.apple.com/account/subscriptions") else { return }
        UIApplication.shared.open(url)
    }

    private func observeCustomerInfo() async {
        for await info in Purchases.shared.customerInfoStream { apply(info) }
    }

    private func apply(_ info: CustomerInfo) {
        let premium = info.entitlements[Self.entitlementID]?.isActive == true
        access = premium ? .premium : .free
        let defaults = UserDefaults.standard
        defaults.set(premium, forKey: Self.cachedPremiumKey)
        if premium { defaults.set(Date(), forKey: Self.cachedPremiumDateKey) }
        else { defaults.removeObject(forKey: Self.cachedPremiumDateKey) }
    }
}
