# Project Memory

Notes the coding agent keeps between sessions. Source code, project configuration, git state, and build output are more authoritative than this file — verify against them before relying on a note.

## Project

Generated iOS SwiftUI application.

- SwiftUI
- XcodeGen project generation: `project.yml` is the project config; do not edit `.xcodeproj/project.pbxproj` directly
- Local state/storage unless the user asks for a backend
- App source lives in the generated app folder named by the project title

Prefer native Apple-like UI. Avoid web-dashboard-style components unless explicitly requested.

## Decisions

- Phase 0 uses a fixed 1024×1024 Core Graphics cat page, a dilated immutable boundary mask, cached connected-component regions, and one transparent RGBA paint surface under immutable line art.
- All paint mutations and UI state are MainActor-confined. Undo/redo stores compressed exact 64×64 before/after tile patches with a 25-action and 48 MB budget.
- UIKit owns canvas touch handling and UIScrollView navigation; one touch/Pencil edits while pan requires two touches. Photos permission is add-only and requested only by Save.
- Phase 1 adds 16 deterministic local vector pages, a three-tab Home/Explore/Gallery shell, persistent favorites, and one local project per page.
- Project metadata is Codable JSON in Application Support; transparent paint and flattened grid thumbnails are separate PNG files. Undo/redo remains session-only.
- The product UI uses an artwork-first editorial system: warm paper background, deep ink, lavender/coral/sky/mint accents, floating navigation, large imagery, and restrained native motion. Engine and canvas layers remain visually isolated from redesign work.
- Phase 3 Now adds a dependency-injected local AI-generation vertical slice: generated-source page metadata, resumable generation state, deterministic complexity-aware fixture art, separate master/thumbnail history storage, Gallery AI Creations, and project-local line-art copies for offline resume.
- Live AI remains backend-gated: existing Supabase + OpenAI Images, Sign in with Apple, RLS-owned generation/history, private Storage, moderation, validation, idempotency, and a server-configurable three-per-day limit belong to Phase 3 Next.
- Phase 4 Now adds an offline-testable Photo Studio: system photo selection, native camera confirmation, square zoom/pan composition, metadata-free bounded JPEG preparation, style/background options, deterministic validated fixture line art, resumable photo history, Gallery revisit/delete, and project-local offline handoff through the unchanged engine.
- Live photo transformation remains backend-gated: private temporary input/output Storage, OpenAI image transformation, post-processing, cleanup, RLS, usage limits, and cross-device history belong to Phase 4 Next.
- Phase 5 uses RevenueCat project `proj6d64c9f8`, one `premium` entitlement, a current Premium offering, and Monthly/Yearly packages with Yearly preferred. The iOS app links a stable anonymous Supabase user ID to RevenueCat and preserves existing projects/creations after entitlement loss.
- Generation limits are server-owned in Supabase: Free uses daily periods, Premium uses monthly periods, entitlement rows are webhook-only, and authenticated generation reservations derive tier server-side under an advisory transaction lock. The local fixture generators now require this reservation before creating history.

## Pitfalls

- `project.yml` is the source of truth; regenerate with XcodeGen rather than editing `project.pbxproj`.
- Never derive a page recipe from Swift `hashValue`; it changes between launches and would misalign persisted paint. Page IDs map to deterministic artwork recipes.
