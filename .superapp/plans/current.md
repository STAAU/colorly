---
title: Phase 5 — RevenueCat, Premium Access, and AI Usage Control
status: approved
updatedAt: 2026-09-08T19:22:00Z
approvedAt: 2026-09-08T19:22:00Z
---
A free user can keep coloring and retain every creation, while contextual premium entry points offer Monthly and Yearly subscriptions through RevenueCat. Premium entitlement reacts immediately to purchase, restore, renewal, refund, and expiration. Costly generation access is decided by authenticated server state and configurable server-time limits, never by a client premium flag.

## Now
1. Add one RevenueCat `premium` entitlement, one current Offering, Monthly and Yearly packages/products, with Yearly preferred. Use RevenueCat offerings and localized StoreKit prices; never hard-code price or trial claims.
2. Add a centralized RevenueCat subscription service with stable anonymous identity linked to an anonymous Supabase user, cached/reactive entitlement states, customer-info refresh, purchase cancellation/pending/error handling, restore, and native subscription management.
3. Add a custom artwork-led native paywall, respectful parent-readable subscription language, real product artwork, concise benefits, dynamic plan choices, retry/loading states, Restore Purchases, Privacy Policy, and Terms of Use.
4. Add contextual paywall routing from premium content, AI/photo limits, Home, and a minimal Settings screen. Do not show a launch paywall.
5. Enforce premium curated page starts while allowing preview/favorite; always allow continuation of an existing project and all existing AI/photo creations after expiration.
6. Add backend tables and RLS for trusted user entitlements, idempotent RevenueCat events, central plan limits, and usage periods/counters. Use server timestamps and transactional allowance reservation.
7. Deploy a secured RevenueCat webhook that validates a server-only authorization value, idempotently maps relevant lifecycle events into trusted entitlement state, and never accepts client-written premium values.
8. Deploy an authenticated generation-access endpoint that derives tier from trusted entitlement state, reads central limits, applies daily Free/monthly Premium periods, and returns typed allowed/limit/offline responses. Existing local fixture generators remain local; this endpoint is the authority required before any future provider call.
9. Add polished limit-reached UX that offers Premium only to Free users and shows reset/fair-use messaging to Premium users. Keep counters contextual rather than persistent.
10. Preserve all engine, project, favorites, cache, Gallery, and creation data. Do not modify Engine or Canvas.

### Verification
- Build the iPhone app and inspect that Engine/Canvas remain unchanged.
- Verify RevenueCat configuration, current offering/package/product links, and `premium` attachment.
- Verify RLS/advisors, webhook idempotency, client inability to write entitlements, server-time period selection, Free/Premium limits, and duplicate reservation safety.
- Manually test free launch, premium page, dynamic offering failure, purchase cancellation/pending/success, restore outcomes, mid-session state changes, expiration, existing-project access, offline cached premium UI, and localized prices on sandbox/physical devices once App Store products and RevenueCat App Store credentials are available.

## Next
1. Create the matching subscription group and products in App Store Connect, set territory prices/localizations/review metadata, and add App Store Connect credentials to RevenueCat; the App Store record does not yet exist for this bundle ID.
2. Add the RevenueCat webhook authorization secret to Supabase and set the deployed webhook URL in RevenueCat, then perform signed sandbox webhook and duplicate-delivery tests.
3. Route the future live text/photo provider functions through the generation-access reservation before charging the provider, and add reservation release/reconciliation for provider failures.
4. Complete App Store listing privacy/support/terms URLs and run the submission-readiness audit.

## Later
- Final commercial allowance tuning after cost and conversion data.
- Optional premium palettes/tools or higher export quality only when those real features exist.
- Ads, coins, consumable credit packs, lifetime purchases, web checkout, community, referrals, chat, and social features.
