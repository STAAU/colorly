---
title: Phase 1 Product Shell and Local Coloring Library
status: approved
updatedAt: 2026-09-08T15:18:47.581Z
approvedAt: 2026-09-08T15:18:47.581Z
proposal:
  messageId: chm_01m20sfbywenc8k8nw0tccgwbf
  toolCallId: call_DBT5sLro1acTVm1GRMx8TuNu
---
## Now

**User-facing outcome:** The app launches into a polished three-tab product shell where a child can browse a bundled coloring library, preview and favorite pages, start or resume multiple independent coloring projects, use the unchanged Phase 0 editor, leave safely, reopen the app later with exact paint restored, and organize work as In Progress or Finished—all locally, with no account or backend.

### Confirmed product decisions

- Preserve the proven Phase 0 fill, brush, eraser, palette, brush sizes, history, reset, zoom/pan, Pencil, layered rendering, Photos export, and adaptive editor behavior.
- Use native Swift/SwiftUI navigation with three bottom tabs: Home, Explore, and Gallery.
- Home includes featured pages, categories, recent unfinished projects, and favorites.
- Explore includes local search, categories, all pages, and a lightweight difficulty filter.
- Category results and library cards use responsive grids: two columns on iPhone and wider adaptive grids on iPad.
- A lightweight page preview provides a large image, title, difficulty, favorite control, and Start/Continue action before opening a new library page; Continue and Gallery cards resume directly.
- The content model includes stable IDs, category, difficulty, premium/featured flags, and source/thumbnail references suitable for later cloud mapping.
- Projects auto-save locally after meaningful edits, when leaving the editor, and when the app backgrounds; large binary paint data does not go into UserDefaults.
- Favorites persist locally without an account.
- Premium is visual metadata only. Every bundled page remains accessible.
- No Supabase, Cloud, accounts, AI, RevenueCat, paywall, purchases, social features, or Phase 2 work.

### Assumptions

- Phase 1 ships 16 local pages across the requested categories: Cat, Dog, Panda, Fox, T-Rex, Triceratops, Car, Fire Truck, Rocket, Astronaut, Planet, Fish, Turtle, Dragon, Unicorn, and Cupcake. The page definitions remain editable seed data.
- One local project is maintained per coloring page in Phase 1. Starting a page with an existing project offers Continue and resumes it rather than silently replacing it.
- Paint is persisted as a lossless transparent PNG at the source page resolution; project metadata is Codable JSON and gallery thumbnails are small flattened images. This preserves exact pixels while keeping grids lightweight.
- Undo/redo history remains an in-memory editing-session feature. The paint resumes exactly after relaunch, but the previous session’s undo stack does not.
- Tapping Done saves immediately, marks the project Finished, and returns to Gallery. Reopening and editing a finished project changes it back to In Progress.
- Photos export remains a separate explicit action; automatic project saving never requests Photos permission.

### Scope and interaction

- Home opens by default. Each tab owns a native `NavigationStack`, while detail, category, and coloring destinations stay shallow and predictable.
- New content cards open a visual preview. Existing project cards bypass preview and resume the exact saved project.
- Cards use large rounded artwork thumbnails, concise titles, visible heart controls, and a small premium badge where applicable. Premium badges never block taps.
- Home sections are omitted or replaced by concise friendly empty states when there is no content. Gallery clearly separates In Progress and Finished.
- The editor gains page-aware title/status behavior and a Done action without changing canvas gestures or pixel-editing behavior. The tab bar is hidden while coloring so the canvas retains the Phase 0 space and focus.
- Auto-save is triggered only at action boundaries—fill completion, stroke completion, undo, redo, reset, Done, editor departure, and backgrounding—and is debounced during active use.

### Implementation steps

1. **Introduce the app-level shell and dependency ownership**
   - Replace the direct `ColoringScreen()` launch in `App/NativeKidsColoringEnginePrototypeApp.swift` with `App/AppRootView.swift` and `App/MainTabView.swift`.
   - Add one main-actor `AppModel` that owns navigation-facing repository state and long-lived service instances; inject it through SwiftUI environment rather than using global singletons.
   - Give Home, Explore, and Gallery independent native navigation stacks and typed destinations for category, page preview, and project editor. Preserve each tab’s position when switching tabs.
   - Observe `scenePhase` at the root and ask the active editor/project coordinator to flush pending work when the app becomes inactive or backgrounds.

2. **Separate catalog metadata from the existing engine’s runtime image input**
   - Expand `Models/ColoringPage.swift` into a stable, Codable, identifiable catalog model with `id`, `title`, `categoryID`, source key, thumbnail key, `difficulty`, `isPremium`, `isFeatured`, and sort order.
   - Add `Models/ColoringCategory.swift`, `Models/ColoringDifficulty.swift`, `Models/ColoringProject.swift`, and `Models/ProjectStatus.swift` using stable string IDs and cloud-friendly scalar fields.
   - Introduce a small runtime `ColoringPageAsset` value containing the selected page metadata, pixel size, and immutable `CGImage`. Keep `ColoringDocument` dependent on this runtime asset contract rather than on catalog/storage concerns.
   - Update hard-coded Cat-specific save/reset copy to use the current page title.

3. **Build the bundled content repository and reusable local artwork provider**
   - Add `Data/LocalContentRepository.swift` behind a read-only `ContentRepository` protocol and put the eight category records plus 16 page records in `Data/SampleContent.swift`; views query the repository instead of embedding source names.
   - Generalize `Sample/SampleCatPageRenderer.swift` into a local line-art provider with page-specific vector recipes rendered at canonical 1024×1024 resolution. Keep every recipe white/transparent with pure black, thick, closed contours and large fillable regions compatible with the existing boundary segmentation.
   - Render card previews directly at thumbnail resolution from the same local vector recipes and cache only bounded thumbnail images with `NSCache`. Resolve a full-resolution line-art image only when opening an editor, so library grids never retain every 1024×1024 page.
   - Keep the Phase 0 Cat recipe unchanged in geometry so its known fill test remains valid.

4. **Adapt the existing editor to accept any selected page without replacing its engine**
   - Change `Coloring/ColoringScreen.swift` and `Coloring/ColoringViewModel.swift` to initialize from a selected `ColoringPageAsset`, optional existing project, and injected persistence services instead of constructing the Phase 0 Cat internally.
   - Leave `Engine/FloodFillEngine.swift`, `Engine/BrushEngine.swift`, history logic, UIKit touch handling, and zoom behavior intact. Continue creating boundary segmentation from each selected immutable line-art image when its editor opens.
   - Extend `Engine/PaintSurface.swift` and `Engine/ColoringDocument.swift` with dimension-validated import/export of the transparent paint layer. Restoring paint must not alter the immutable source line art; display and Photos export remain white background → restored/user paint → source line art.
   - Add lightweight document signals for meaningful mutations and whether any paint exists. Use these for auto-save/status updates without publishing per-touch pixel state through SwiftUI.
   - Add a page-aware editor title and Done action while retaining Reset and Photos Save. Hide the tab bar during editing and preserve all compact/regular Phase 0 layouts.

5. **Implement durable, efficient local project persistence**
   - Add `Services/ProjectStorageService.swift` as an actor-backed FileManager/Codable store under Application Support. Persist an atomically replaced project index plus per-project transparent paint PNG and thumbnail files using stable relative paths.
   - Add `Services/ThumbnailService.swift` to create a small flattened project thumbnail from white background, paint, and immutable line art after an autosave. Never decode full-resolution paint in Home or Gallery cards.
   - On Start, create project metadata immediately. On resume, load and dimension-check the project’s paint PNG before constructing the document. A missing/corrupt paint file falls back safely to an empty layer while surfacing no crash.
   - Debounce saves after edit completion, coalesce overlapping requests per project, and force-flush on navigation dismissal, scene background, Done, and app termination opportunities. Write temporary files and atomically replace destinations so interrupted saves do not corrupt the last good project.
   - Update `createdAt`, `updatedAt`, status, paint path, and thumbnail path only after successful persistence. Keep only the active project’s full-resolution paint in memory.

6. **Persist and expose favorites cleanly**
   - Add `Services/FavoritesService.swift` with a small Codable set of page IDs stored locally; expose idempotent toggle/query operations and validate IDs against the local repository.
   - Wire the same favorite state to Home, Explore, Category, and Preview cards so hearts update consistently and remain set after relaunch.
   - Show the requested favorites empty state when no pages are saved.

7. **Build reusable library components and preview flow**
   - Add `Explore/ColoringPageCard.swift` as the shared artwork card with cached thumbnail, title, heart button, accessibility labels, and non-blocking premium badge.
   - Add `Explore/ColoringPagePreviewView.swift` with a large local preview, difficulty label, favorite action, and Start Coloring or Continue Coloring button based on project existence.
   - Keep card hit areas and nested favorite buttons unambiguous so tapping the heart does not also navigate.

8. **Build Home around visual, live local data**
   - Add `Home/HomeView.swift`, `Home/FeaturedSection.swift`, `Home/CategorySection.swift`, `Home/ContinueColoringSection.swift`, and `Home/FavoritesSection.swift`.
   - Use horizontally scrolling featured/favorite/project cards and compact category tiles. Sort Continue Coloring by `updatedAt` descending and limit it to recent In Progress projects.
   - Refresh sections from the shared app model after favorite changes, autosaves, status changes, or returning from the editor; no fake loading UI is shown for bundled content.

9. **Build Explore, search, categories, and adaptive grids**
   - Add `Explore/ExploreView.swift`, `Explore/CategoryView.swift`, and `Explore/SearchResultsView.swift`.
   - Use native `.searchable` title matching with trimmed, case/diacritic-insensitive local filtering and immediate results. Display “No coloring pages found.” only for a real empty query result.
   - Provide simple All/Easy/Medium/Detailed filter chips or a compact menu without turning Explore into a dashboard.
   - Use an adaptive `LazyVGrid` whose minimum card width yields two columns on iPhone and approximately three to five on iPad. Category cards navigate to the same shared grid/card components.

10. **Build the local Gallery and project lifecycle**
    - Add `Gallery/GalleryView.swift` and `Gallery/ProjectCard.swift` using persisted thumbnail paths, page titles resolved through the content repository, and friendly relative last-edited dates.
    - Present separate In Progress and Finished sections with the requested empty state: “Your colorful creations will appear here.”
    - Project cards resume directly. Done saves first, changes status to Finished, refreshes Gallery/Home, and dismisses the editor. Any later pixel edit marks a reopened finished project In Progress and updates its thumbnail/date.

11. **Polish adaptive presentation without touching engine behavior**
    - Use system backgrounds, restrained soft surfaces, one friendly blue accent, large native typography, SF Symbols, and artwork-led cards. Avoid excessive gradients, shadows, or clip-art chrome.
    - Keep minimum 44×44-point actions, safe-area-aware tab/navigation bars, Dynamic Type-friendly labels, and accessibility descriptions for page title, difficulty, favorite, premium indicator, project status, and dates.
    - Constrain horizontal card widths on iPad and let grids gain columns rather than stretching phone cards. Verify the existing side-deck editor and Apple Pencil path remain unchanged.

### Verification

- Regenerate the Xcode project from `project.yml` only if source/config changes require it, then build the app for both an iPhone simulator and an iPad simulator.
- Execute all 15 requested manual tests: Home launch, three-tab navigation, Animals category, Cat then Rocket editor reuse, fill, brush, 5× zoom/two-finger pan, leave/autosave, terminate/relaunch persistence, exact resume, Finished status movement, favorite persistence, Dragon search, independent projects, and iPad grid/Pencil behavior.
- Add persistence edge checks: background immediately after a stroke; rapidly perform several actions before debounce fires; leave during a pending save; relaunch after force-quit; reopen a finished project and edit; reset then leave; corrupt or remove one paint file; and verify other projects still load.
- Compare the transparent paint pixels before leaving and after resume, then flatten both with the same line art to confirm exact restoration and immutable outlines.
- Confirm grid screens load thumbnails rather than full-resolution paint files, memory remains bounded while scrolling all 16 pages/projects, and only the active editor holds its full paint surface and segmentation.
- Re-run the complete Phase 0 interaction suite on Cat and at least one non-Cat page, including fill boundaries, brush, eraser, undo/redo, reset, max zoom, panning, zoomed coordinate accuracy, Apple Pencil where hardware is available, and Photos export.
- Automated tests are intentionally outside this MVP; verification is build plus focused manual device/simulator checks.

### Material risks and mitigations

- **Engine regression during model refactor:** Keep `ColoringDocument`, raster tools, touch bridge, and layer order intact; adapt only the page input and paint import/export seams, then rerun Phase 0 tests on multiple assets.
- **Invalid local artwork boundaries:** Derive all pages from closed vector recipes and validate representative fills in every recipe before shipping the sample library.
- **Interrupted or excessive saves:** Save only at action boundaries with debounce/coalescing, write atomically, and force-flush on navigation/background transitions.
- **Resume mismatch:** Persist the raw transparent paint layer losslessly with page ID and dimensions, reject incompatible files, and never persist a flattened image as editable state.
- **Memory pressure:** Cache bounded low-resolution thumbnails, lazily resolve full page assets, and release editor documents/segmentation when navigation closes.
- **Metadata/file drift:** Keep relative paths in project records, update metadata only after file writes succeed, and tolerate individual missing files without invalidating the full project index.
- **Favorite/project UI staleness:** Use one shared observable app model fed by repository/service results so every tab refreshes from the same local source of truth.
- **Swift 6 isolation:** Keep Core Graphics document mutations on MainActor and filesystem encoding/writes inside the storage actor; transfer owned `Data` snapshots rather than mutable CGContext state.

## Next

No additional build is included in this request. Stop after the complete local Phase 1 experience and its verification; do not begin Phase 2 automatically.

## Later

- Superapp Cloud enablement, user accounts, authentication, cloud gallery, cross-device sync, remote content, and server logic.
- AI generation, photo-to-coloring, OpenAI/Gemini or other secret-holding integrations.
- RevenueCat, subscriptions, paywalls, purchases, and premium access enforcement.
- Community, shared likes, comments, public profiles, social systems, notifications, daily challenges, streaks, ads, and admin tooling.
