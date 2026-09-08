---
title: Phase 0 Native Coloring Engine Prototype
status: approved
updatedAt: 2026-09-08T14:40:35.420Z
approvedAt: 2026-09-08T14:40:35.420Z
proposal:
  messageId: chm_01m20q44p2esq9xw7s5gkyjt2m
  toolCallId: call_8qZdkbQ8IeM7Qz62fBOZSBAJ
---
## Now

**User-facing outcome:** A child can open one native coloring screen, color a built-in cat with precise region fills or freehand strokes, erase only their paint, navigate the page with zoom and pan, undo or redo up to 25 edits, reset after confirmation, and save a crisp flattened result to Photos. The build stops at this Phase 0 engine prototype.

### Confirmed product decisions

- Native Swift/SwiftUI app using Apple frameworks only; no web or cross-platform layer.
- One screen and one built-in 1024×1024 black-and-white cat page designed specifically for region-fill testing.
- Fill correctness, canvas responsiveness, outline preservation, and touch-coordinate accuracy take priority over decoration.
- Tools: Fill, Brush, Eraser, Undo, Redo, Reset, and Save.
- Brush and eraser each have Small, Medium, and Large sizes.
- Palette has 11 large swatches: red, orange, yellow, green, cyan, blue, purple, pink, brown, black, and light gray.
- One-finger or Apple Pencil input colors the page; two-finger gestures navigate it.
- Native Photos add-only permission and a user-friendly denied/error state are required.
- iPhone and iPad layouts are supported, including reasonable landscape behavior.
- Visual tone is bright, clean, modern, child-friendly, and restrained rather than decorative or toy-like.
- No backend, accounts, AI, subscriptions, content library, onboarding, social features, or other Phase 1 work.

### Assumptions

- Phase 0 keeps one active editing session in memory. The persistent output is the user’s explicit flattened Photos save; editable projects and a local gallery remain later work.
- Filling an already painted region recolors the complete original line-art region. The fixed line-art boundary map—not existing brush color—is the source of truth.
- Reset clears the paint layer and its undo/redo history after confirmation; Save does not alter history.
- Background outside the cat may also be colored as one page-bounded region.
- The chrome uses an off-white canvas surround, white controls, and a friendly blue selection accent; the saturated coloring palette remains the dominant color.

### Scope and interaction

- Keep the canvas as the visual focus. On compact iPhones, place history/export actions in a concise top bar and tools, size choices, and a horizontally scrollable palette in a bottom control deck. On iPad/regular width, constrain controls to a compact rail/deck rather than stretching them across the display.
- Use fixed, large tap targets, SF Symbols plus short labels, an obvious selected-tool state, disabled Undo/Redo states, and no hidden menus.
- Fit the complete square page at minimum zoom and allow approximately 5× magnification relative to fit. Center the page when it is smaller than the viewport and clamp scrolling so it cannot be lost off-screen.
- Fill is a single tap. Brush and eraser use one direct touch or Apple Pencil, including coalesced native touch samples for smooth rounded strokes. The scroll view’s pan requires two fingers, while pinch remains a two-finger gesture, preventing routine drawing/navigation conflicts.
- A native confirmation dialog protects Reset. Save reports success, denial, or failure without crashing.

### Implementation steps

1. **Configure the native targets and permissions**
   - Update `project.yml`, the XcodeGen source of truth, rather than the generated `.xcodeproj`.
   - Change `TARGETED_DEVICE_FAMILY` from iPhone-only to iPhone and iPad while preserving iOS 17 and Swift 6.
   - Add `NSPhotoLibraryAddUsageDescription` for add-only Photos access, retain the declared phone/tablet orientations, and regenerate the project after source work is complete.

2. **Create the app shell and explicit state model**
   - Add `App/NativeKidsColoringEnginePrototypeApp.swift` as the entry point and `Coloring/ColoringScreen.swift` as the only product screen.
   - Add `Coloring/ColoringViewModel.swift` as a main-actor observable coordinator for selected tool, selected RGBA color, brush size, processing state, save/reset presentation, and history availability. Keep per-touch pixel updates outside SwiftUI observation so strokes do not invalidate the entire screen.
   - Add focused models such as `Models/ColoringTool.swift`, `Models/BrushSize.swift`, `Models/PaletteColor.swift`, `Models/ColoringPage.swift`, and `Models/DrawingAction.swift`. Engine colors use stable RGBA values rather than depending on SwiftUI `Color`.

3. **Build a reusable test page and layered document**
   - Add `Sample/SampleCatPageRenderer.swift` to draw a canonical 1024×1024 page with Core Graphics paths: white background; thick, solid black contours; centered head, separate ears, body, paws, tail, and face details; large closed interiors; no gray, shading, texture, or preexisting color.
   - Represent the page independently from the screen through a `ColoringPage` contract containing identity, canvas size, immutable line-art image, and boundary information. This lets later remote or generated pages enter the same engine without changing the editor.
   - Add `Engine/ColoringDocument.swift` and `Engine/PaintSurface.swift` for a transparent mutable RGBA paint layer. Render in strict order: opaque white background, user paint, then immutable line art. Brush, eraser, fill, reset, and history mutate only the paint surface, so black outlines cannot be erased or covered.

4. **Implement robust region segmentation and fill**
   - Add `Engine/BoundaryMaskBuilder.swift` to derive a binary barrier mask from line-art alpha/luminance. Include low-alpha antialiased edge pixels and apply a small morphological close/dilation so tiny edge gaps cannot become leaks.
   - Add `Engine/FloodFillEngine.swift` as a UI-independent native service. On page load, use an iterative scanline/connected-component pass on a serial background worker to label all non-boundary regions and store compact row spans plus bounds for each region. Avoid recursive or per-pixel object allocation.
   - A fill tap converts the page coordinate to an integer pixel, looks up the region, updates only that region’s spans on a working paint surface, records one history transaction, and commits the result atomically. Expensive segmentation, fill preparation, and compression do not block SwiftUI’s main thread; concurrent edits are serialized to prevent surface races.
   - Ignore taps on boundary pixels and preserve the prior document if work is cancelled or fails. Cache region data for the page so subsequent fills are proportional to the selected region and do not repeatedly scan the full image.

5. **Implement brush, eraser, and unified editing history**
   - Add `Engine/BrushEngine.swift` to interpolate between coalesced touch samples and rasterize round-capped segments at logical canvas coordinates. Brush uses source-over color; eraser clears alpha from the same paint surface, revealing white while leaving the separate line-art layer untouched.
   - Journal modified pixel tiles once per gesture/fill and finalize a single `DrawingAction` when the operation ends. Store compressed before/after tile patches using Apple’s Compression framework so undo/redo is exact for fills, brush strokes, and eraser strokes without retaining whole-image snapshots for every action.
   - Add `Engine/HistoryManager.swift` with separate undo/redo stacks, a 25-action limit, and a defensive memory budget that evicts the oldest transactions. A new edit clears redo. Reset clears both stacks only after confirmation.
   - Keep the paint surface and mutable history behind one serialized engine boundary. Publish only lightweight UI state and display invalidations.

6. **Create the native canvas and gesture bridge**
   - Add `Canvas/ColoringCanvasRepresentable.swift` to bridge SwiftUI to a purpose-built UIKit canvas, and split the UIKit implementation into `Canvas/ColoringScrollView.swift` and `Canvas/ColoringPageView.swift`.
   - Use `UIScrollView` for native pinch/zoom, bounded two-finger pan, centering insets, and rotation/layout updates. The page view remains in canonical 1024×1024 coordinates; touch locations requested in that view map directly to image pixels at every zoom level.
   - Give drawing recognizers exactly one touch and permit direct touch plus stylus input. Feed coalesced `UITouch` samples to the brush engine; cancel or finish a stroke cleanly when a two-finger navigation gesture takes over.
   - Draw only invalidated dirty regions while stroking and composite immutable snapshots/layers without causing SwiftUI body refreshes. Preserve the relative zoom and visible page center across layout changes where possible.

7. **Assemble child-friendly controls and responsive layouts**
   - Add `Components/ColoringToolbar.swift`, `Components/ColorPalette.swift`, `Components/BrushSizePicker.swift`, and `Components/CanvasStatusOverlay.swift`.
   - Provide at least 44×44-point targets, selected rings/backgrounds, concise accessibility labels, and clear disabled states. Show the size picker only for Brush or Eraser without shifting the canvas unpredictably.
   - Use adaptive SwiftUI layout based on available size class and geometry: compact bottom controls on iPhone; a bounded control area and larger centered canvas on iPad/landscape. Avoid dashboard cards and professional design-tool density.

8. **Flatten and save through native Photos APIs**
   - Add `Services/PhotoSaveService.swift` using `PHPhotoLibrary.requestAuthorization(for: .addOnly)` and `PHPhotoLibrary.performChanges`.
   - Add an engine export method that creates an sRGB flattened image at the page’s native resolution in the same guaranteed order: white, paint, crisp line art.
   - Request permission only after Save is tapped. Surface limited/authorized success, denied/restricted guidance, and unexpected save failure through a simple native alert; never mutate the editable document during export.

### Verification

- Regenerate from `project.yml`, then build and run the app with the selected iPhone simulator target. Also build an iPad simulator destination and check portrait and landscape layouts.
- Execute the 13 requested manual tests in order: isolated body fill, ear boundary containment, independent multi-region fills, smooth brush, outline preservation, eraser behavior, three-step undo, three-step redo, zoom, pan, drawing while zoomed, Photos save, and confirmed reset.
- Add focused manual edge checks: tap directly on a black line; rapidly request fills; begin drawing then add a second finger; draw at page edges; rotate while zoomed; deny Photos access; fill after brushing; erase part of a filled region; exhaust more than 25 edits; and verify redo clears after a new edit.
- Inspect a saved image at full resolution to confirm a white background, exact paint placement, and the immutable black line layer on top.
- Use Xcode’s Time Profiler and memory gauges during repeated full-background fills, long strokes, zooming, and 25 history actions. Confirm there is no visible main-thread freeze, runaway history growth, or full-screen SwiftUI redraw per touch. Automated tests are intentionally not part of this MVP.
- Validate final touch feel and Apple Pencil behavior on physical iPhone/iPad hardware when available; simulator checks cannot fully prove stylus latency or real multi-touch ergonomics.

### Material risks and mitigations

- **Boundary leakage:** Antialiased or imperfect contours can connect regions. Use a dedicated closed vector test page, conservative barrier-mask construction, and morphological gap closing; line taps perform no fill.
- **History memory:** Full 2048×2048 snapshots would grow quickly. Use changed-tile deltas, compression, an action-count limit, and a byte budget.
- **Touch/zoom offsets:** Independent SwiftUI transforms can drift. Keep navigation and touch conversion in one UIKit scroll/page coordinate system and test after rotation and at maximum zoom.
- **Input races:** Background fills and live strokes could mutate one buffer simultaneously. Serialize document operations and commit background-prepared fills atomically.
- **Outline degradation:** Flattening paint into the source art could soften or erase lines. Keep immutable line art as a separate top layer for both display and export.
- **Swift 6 concurrency:** Mutable Core Graphics buffers are not freely sendable. Confine each mutable surface to its engine boundary and transfer immutable images or owned data copies between execution contexts.

## Next

No next build is included in this request. Stop after the Phase 0 prototype and its manual verification; any Phase 1 scope must be explicitly selected and approved before implementation.

## Later

- Editable project persistence, local/cloud galleries, timelapse, expanded palettes, premium tools, and optional “Stay Inside Lines” brush assistance.
- Remote coloring libraries, categories, difficulty levels, hundreds of pages, daily coloring, streaks, and challenges.
- Cloud/backend enablement, accounts, authentication, cross-device sync, secure storage, and server logic.
- AI-generated pages, photo-to-coloring conversion, and secret-holding external AI integrations.
- RevenueCat, subscriptions, paywalls, and other monetization.
- Onboarding, notifications, profiles, community, likes, comments, social sharing systems, and ads.
