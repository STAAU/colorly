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

None yet.

## Pitfalls

None yet.
