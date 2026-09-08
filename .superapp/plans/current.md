---
title: Phase 3 — Secure AI Coloring Page Generation
status: approved
updatedAt: 2026-09-08T17:03:12.283Z
approvedAt: 2026-09-08T17:03:12.283Z
proposal:
  messageId: chm_01m20z46d6enc8k97bmnvpp50e
  toolCallId: call_6ZJWJZMcJqbOjlOqxjVeieo4
---
A signed-in user can describe a picture, choose Simple/Medium/Detailed, generate a flood-fill-ready black-and-white page through a secure Supabase/OpenAI pipeline, preview it, start coloring with the existing engine, and recover the creation later from Gallery.

### Confirmed product decisions
- Preserve the current native coloring engine, canvas, local projects, premium visual system, Home/Explore/Gallery navigation, and all existing coloring behavior.
- Use the existing Supabase project as the backend foundation; no provider secret may ship in the iOS app.
- Use OpenAI Images behind a Supabase Edge Function.
- Require an authenticated account for AI creation, history, and server-enforced usage.
- Enforce a configurable development limit of three generations per account per UTC day.
- Add only Phase 3. Photo conversion, RevenueCat, paywalls, ads, social/community features, chat, and notifications remain out of scope.
- The supplied `#69D2E7`, `#A7DBD8`, `#E0E4CC`, `#F38630`, `#FA6900` palette will be used selectively for the Create experience while retaining the established product visual system.

### Assumption requiring configuration
- Because the account-method response did not identify an authentication method, use native Sign in with Apple backed by Supabase Auth. The Supabase Apple provider, Apple capability, service identifiers, and redirect configuration must be supplied/configured before live sign-in can complete.
- The repository currently contains no Supabase SDK, remote-content implementation, networking layer, backend schema, or Edge Function despite those being described as existing. This plan adds those foundations rather than assuming unavailable code.

## Now
Deliver a backend-ready local vertical slice without changing the engine:

- Add `ColoringPageSource` (`curated`, `generated`, reserved `futurePhoto`) and generated-page metadata contracts while keeping source irrelevant to `ColoringDocument` and paint operations.
- Add a dependency-injected AI generation service protocol, state machine (`idle`, `submitting`, `generating`, `processing`, `completed`, `failed`), typed friendly errors, and persisted pending-generation identifiers.
- Build the premium Create screen: 300-character prompt field, rotating local suggestion chips, Simple/Medium/Detailed selector, keyboard-safe scrolling, duplicate-submit prevention, accessible controls, and restrained generation motion/messages.
- Add a prominent “Create with AI” Home hero/action and route, without turning Home into a dashboard.
- Add result preview actions for Start Coloring, Generate Again, Save for Later, and Edit Idea.
- Add editable local seed generation records and coloring-ready fixture imagery so the full UI, generated-source model, local caching contract, Gallery “AI Creations” section, deletion confirmation, and handoff into the existing `ColoringScreen` can be exercised before live backend enablement.
- Store generated master/thumbnail files separately from paint files in Application Support; copy the master locally before creating a project so resumed coloring works offline.
- Keep generated metadata Codable and repository-backed so replacing the local fixture service with Supabase is a service swap, not a UI or engine rewrite.

### Implementation steps
1. Extend `Models/ColoringPage.swift` with source/origin and remote/local asset references using backward-compatible Codable defaults for existing curated pages.
2. Add focused generated-content models under `Models/` for complexity mapping, generation status, persisted record, request/response DTOs, and user-facing failure categories.
3. Add `Services/AIGenerationService.swift`, a local fixture implementation, a generated-asset cache, and a generated-history repository. Use atomic JSON/PNG writes and thumbnail-sized Gallery reads.
4. Extend `App/AppModel.swift` with generation/history state and unified page lookup that can resolve curated and generated pages without changing the engine.
5. Add `Create/AI/CreateView.swift`, generating/result states, suggestion components, and an account-required surface. Keep the feature visually native rather than chatbot-like.
6. Update `Home/HomeView.swift`, `Gallery/GalleryView.swift`, and routing to expose Create prominently and add AI Creations/history/delete flows.
7. Update only the editor-loading boundary so a cached generated `CGImage` becomes the same `ColoringPageAsset` already consumed by `ColoringViewModel` and `ColoringDocument`. Do not modify `Engine/` or `Canvas/`.
8. Update `project.yml` for new source files; do not edit generated Xcode project configuration directly.

### Now verification
- Build the iPhone target successfully with no new compiler warnings.
- Verify prompt limits, keyboard avoidance, complexity selection, duplicate-tap suppression, generation-state restoration, friendly failure/retry, result actions, Gallery persistence, deletion confirmation, and thumbnail-only grid loading.
- Start a seeded generated page, fill multiple regions, brush across line art, erase paint, undo/redo, zoom/pan, leave/relaunch, and confirm exact project resume.
- Confirm no files under `Engine/` or `Canvas/` changed and no secret/API key appears in app sources or generated configuration.
- Automated tests are not part of this MVP slice.

## Next
1. **Enable Cloud / connect the existing Supabase project** — add the public project URL and anon key to non-secret app configuration, add the Supabase Swift client, and unlock authenticated generation, durable server history, Storage, database policies, and Edge Functions.
2. **Configure Sign in with Apple** — enable the Apple capability/provider and exchange the native nonce-protected ID token for a Supabase session; gate Create/history while leaving curated coloring available signed out.
3. **Apply database migrations** — create `ai_generations` and `ai_usage` with enums/status constraints, ownership timestamps, normalized prompt, storage paths, provider audit fields hidden from UI, error code, unique idempotency key, and row-level-security policies restricting rows to `auth.uid()`.
4. **Create private generated-content Storage paths** — store masters and thumbnails under `generated/YYYY/MM/<user-id>/<generation-id>/`, prohibit public writes, and return short-lived signed URLs only to the owner.
5. **Deploy `generate-coloring-page`** — authenticate the JWT, validate a 1–300 character prompt and known difficulty, enforce idempotency/rate limits/three-per-day transactionally, run server-side moderation, insert a queued record, and return its ID immediately.
6. **Run generation asynchronously** — use `EdgeRuntime.waitUntil` within documented runtime limits to enrich the prompt by complexity, call OpenAI Images with a server-held secret, transition queued → generating → processing, and preserve the row even if the client disconnects.
7. **Post-process and validate output server-side** — decode a square image, normalize to 1024×1024, grayscale, increase contrast, threshold to true black/white, remove isolated noise where practical, generate a thumbnail, and reject blank/low-white/low-line-density/undecodable output before upload. Record only friendly error codes.
8. **Complete safely and count usage** — upload assets, atomically mark the generation completed, and increment usage only for successful or explicitly provider-billable attempts; technical retries reuse the idempotency key and cannot double-count.
9. **Connect the iOS live service** — submit once, persist the generation ID immediately, poll status with bounded backoff after foreground/network recovery, map backend errors to offline/timeout/rejected/limit/provider/storage messages, and replace fixture records with owner-scoped server history.
10. **Cache completed assets locally** — download thumbnails for history, fetch the full master only for preview/start, validate/decode before display, and retain the project’s local line-art copy for offline continuation.
11. **Perform live manual acceptance** — run all twelve requested tests, including Simple versus Detailed output, flood-fill leakage checks, unsafe prompt rejection, provider failure, offline behavior, app background recovery, duplicate submission, daily limit, and termination/relaunch project resume.

## Later
- Photo-to-coloring, RevenueCat, subscriptions, paywalls, ads, community/public posting, comments, followers, profiles, chatbot/voice features, streaks, and notifications.
- Provider/model controls, seeds, steps, negative prompts, raw moderation classifications, and resolution controls in the client.
- Public/shared generated assets or deletion of curated editorial content.
- Automatic commercial entitlement tiers; the server-side usage design is prepared for them, but three-per-day remains the configurable development policy for this phase.
