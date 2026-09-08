---
title: Phase 4 — Photo to Coloring Page
status: approved
updatedAt: 2026-09-08T17:34:43.357Z
approvedAt: 2026-09-08T17:34:43.357Z
proposal:
  messageId: chm_01m21186byenc8k997djtjw1q5
  toolCallId: call_FgXCuwLyZIOebCB43Z9KTWIM
---
A user can choose or take a photo, compose it into a square, select a coloring style and background treatment, preview a flood-fill-compatible photo-derived page, start coloring through the existing engine, and revisit the creation from Gallery.

**Confirmed product decisions**
- Preserve the existing native coloring engine and all completed Home, Explore, Gallery, AI creation, persistence, and premium visual behavior.
- Make **Use a Photo** highly visible beside **Describe with AI** in Home’s creation area.
- Use the system Photos picker without requesting broad library access; request Camera access only after the user taps **Take Photo**.
- Offer only Simple, Classic, and Detailed styles plus Simplify/Keep background, defaulting to Classic + Simplify.
- Use OpenAI Images server-side behind the existing Supabase project; no provider credential may ship in the app.
- Include the currently missing Supabase/Auth foundation as a prerequisite. Supabase connection and deployment access will be available during that step.
- Keep originals private and temporary, strip metadata through re-encoding, retain generated outputs/history, and enforce a configurable server-side development limit of two photo conversions per day.
- Successful photo output must enter the same `ColoringDocument` path as curated and prompt-generated pages.

**Assumptions**
- Native Sign in with Apple backed by Supabase Auth remains the account method established by the approved Phase 3 roadmap.
- Camera capture will use Apple’s native camera controller bridged into SwiftUI; custom camera controls are out of scope.
- The generated asset remains square at the engine’s existing 1024×1024 page contract; client upload preparation uses a high-quality 1536–2048 px square JPEG.

## Now

### Outcome
A complete native, offline-testable Photo to Coloring vertical slice: choose a system photo or take one with the native camera, confirm the capture, crop/position it, choose style/background, run an asynchronous dependency-injected local fixture conversion, preview the result, start coloring with the unchanged engine, and revisit/delete it from My Creations.

### Scope and implementation
1. **Extend source and generation contracts**
   - Extend `ColoringPageSource` in `Models/ColoringPage.swift` with `photoGenerated`, preserving backward decoding for existing curated and AI records.
   - Add Codable photo-generation models for source, style, background mode, uploading/processing/cleaning/completed/failed state, typed failures, local asset paths, timestamps, and hidden/deleted history state.
   - Keep photo records separate from prompt-generation records while using the same generated-page lookup and editor-loading boundary.

2. **Add the Home entry and flow routing**
   - Update `Home/HomeView.swift` so the creation area presents **Describe with AI** and **Use a Photo** as equally clear, artwork-first actions.
   - Present the Photo flow modally without changing the three-tab navigation model.

3. **Implement privacy-preserving native photo acquisition**
   - Add a PhotosUI `PhotosPicker` restricted to images; load only the selected item and never request full photo-library access.
   - Add a native camera wrapper with just-in-time `AVCaptureDevice` authorization handling for authorized, denied, restricted, and unavailable-camera states.
   - Require a captured-photo confirmation with **Retake** and **Use Photo** before continuing.
   - Add the camera usage description through `project.yml`; do not edit project generation internals directly.

4. **Normalize, validate, and compose the source image**
   - Add an image preparation service that normalizes orientation, rejects corrupt/blank/too-small/unsupported inputs, downsizes without repeatedly decoding full-resolution images, and re-encodes to JPEG without EXIF/location metadata.
   - Build a focused square crop/composition screen using a UIKit-backed zoom/pan surface, with reset and confirm actions and no general photo-editing tools.
   - Keep one prepared source plus a lightweight preview in memory; store the active prepared source in temporary local application storage so retry and interruption do not force reselection.

5. **Build the visual conversion experience**
   - Add the large photo preview, concise photo-quality guidance, Simple/Classic/Detailed selector, Simplify/Keep background selector, and one primary **Make Coloring Page** action.
   - Disable duplicate submission and show distinct uploading, processing, and cleaning messages without fake percentages.
   - Use restrained transitions and respect Reduce Motion.

6. **Create a dependency-injected local fixture conversion**
   - Add a `PhotoGenerationService` protocol shaped for the later Supabase implementation.
   - Implement a deterministic local fixture service that derives a clean, validated black-on-white coloring asset from the prepared composition while clearly remaining a development fixture rather than claiming production AI identity preservation.
   - Keep this fixture out of engine code; no Sobel/Canny output is presented as the production transformation.
   - Produce separate 1024×1024 master and thumbnail files, validate dimensions/light background/dark-line density/noise bounds, and return a friendly retry state for invalid output.

7. **Persist and recover the local task/result**
   - Add atomic local repositories for photo-generation history, pending task ID/options, prepared source, master output, and thumbnail.
   - Restore an interrupted fixture conversion after relaunch and preserve completed output after leaving the flow.
   - When coloring starts, copy the output into project-local line-art storage before allowing history deletion so the project remains offline-resumable.

8. **Use the existing engine and Gallery**
   - Create a normal `ColoringProject` and load the photo-derived raster through the existing asset boundary into `ColoringScreen`; do not modify `Engine/` or `Canvas/`.
   - Add photo creations to My Creations with artwork-first cards and no technical badge clutter.
   - Add result revisit, **Try Again** with the same active source, **Choose Another Photo**, style adjustment, and confirmed deletion that cannot remove unrelated projects.

### Verification
- Regenerate from `project.yml` and build the iPhone target.
- Confirm no `Engine/` or `Canvas/` files changed and no provider secrets/networking/backend authority were added to this local slice.
- Manually verify Photos picker orientation, camera permission denial, capture Retake/Use Photo, square crop zoom/pan, all style/background choices, duplicate-submit prevention, processing transitions, result preview, flood fill/brush/eraser/undo/redo/zoom/Pencil handoff, Gallery revisit/delete, relaunch restoration, and offline project resume.
- Exercise corrupt, blank, dark, too-small, unsupported, and invalid-output failures with editable fixture inputs.

### Material risks
- The local fixture proves acquisition, composition, persistence, recovery, validation, and engine compatibility, but it cannot prove recognizable person/pet transformation; that requires the confirmed OpenAI/Supabase step.
- Camera capture and permission behavior require a physical iPhone; the simulator can verify only unavailable-camera handling and Photos selection.
- Large HEIC/iCloud-backed assets can fail or arrive slowly, so loading must remain cancellable and memory-bounded.

## Next

1. **Enable Cloud / connect Supabase** — add the public project URL and publishable/anon key through non-secret build configuration, the Supabase Swift dependency, and deployment linkage; this unlocks Auth, private Storage, RLS, Edge Functions, durable history, cleanup, and server-controlled usage.
2. **Configure native Sign in with Apple** — establish nonce-protected Supabase sessions and account-gate photo conversion while leaving local curated coloring available signed out.
3. **Apply the private photo schema and Storage policies** — create `photo_generations`, owner-scoped RLS, separate private `photo-inputs-temp` and `photo-coloring-output` buckets/paths, signed access, typed statuses/errors, idempotency keys, and indexes without storing unnecessary metadata.
4. **Deploy the authenticated upload/start/status/delete API** — accept only validated style/background options and owned temporary object paths, prevent duplicate jobs, expose resumable status, and perform ownership-safe deletion.
5. **Deploy OpenAI Images transformation** — enrich the private server prompt for subject-first identity preservation, style/detail/background rules, child-safe handling, and no text/watermark/shading; never expose the prompt or key to iOS.
6. **Add server-side cleanup and quality normalization** — normalize grayscale/contrast/threshold, cautiously close small gaps, validate dimensions/background/line density/noise/blankness, reject unsuitable group/dark/blurry inputs, upload separate master/thumbnail outputs, and delete successful or abandoned originals according to policy.
7. **Enforce usage and safety server-side** — track photo conversions separately, enforce a configurable two-per-day development limit, moderate requests/content, and return friendly stable error codes; do not trust client counters.
8. **Swap the fixture service for Supabase** — upload prepared JPEGs with meaningful upload state, start jobs, persist task IDs, poll/recover after backgrounding or network loss, cache completed private outputs locally, and retain same-source retry until the session ends.
9. **Sync photo history and deletion** — reconcile owned cloud history into My Creations, retrieve existing output without regenerating, and remove only the selected cloud output while preserving unrelated/local coloring projects.
10. **Run live acceptance on physical devices** — verify people, pets, groups, noisy backgrounds, all styles, identity preservation, flood-fill leakage, camera/Photos permissions, network interruption, app backgrounding, server limits, RLS isolation, temporary-source cleanup, and offline project resume.

## Later

- RevenueCat, subscriptions, paywalls, final commercial allowances, and ads.
- Public/community photo posting, social feeds, followers, comments, chat, or sharing private child-photo creations.
- General photo filters, a full photo editor, video, AR, or batch conversion.
- Changes to the proven coloring engine or a separate photo-coloring engine.
- Automated tests are not part of this MVP.
