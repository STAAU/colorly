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

## Pitfalls

- `project.yml` is the source of truth; regenerate with XcodeGen rather than editing `project.pbxproj`.
