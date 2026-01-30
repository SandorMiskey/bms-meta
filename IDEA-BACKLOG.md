# Idea Backlog

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Purpose
- Capture raw ideas that arise outside the active roadmap work.
- Triage ideas into the roadmap, docs, or code when ready.
- Remove or move items once they are planned or implemented.

## Workflow
1. Add new ideas to "New / Unsorted" with an optional phase tag.
2. Move items to "Triaged" once a target area is identified.
3. Move items to "Moved" with a short note about where they landed.

## New / Unsorted
- [Phase 1/2 candidate | Planned] UI (including TUI) should support tabs with customizable views.
- [Phase 1 candidate | Consideration] Review whether config loader duplication (runtime vs. overlay) should be refactored into a shared helper once the merge pipeline stabilizes.
- [Phase 2 candidate | Consideration] Consider Wails instead of Tauri/Electron for the desktop client. Wails is a Go-focused desktop framework that packages a web UI with native bindings; it can simplify Go integration but has a smaller ecosystem than Tauri/Electron.
- [Phase 2 candidate | Consideration] Web/Electron/Tauri client: start only after TUI features and integrations are well advanced.
- [Phase 5 candidate | Consideration] SaaS observability baseline: OpenTelemetry instrumentation with LGTM stack (Loki/Grafana/Tempo/Mimir).
- [Phase 5 candidate | Consideration] Evaluate CouchDB for offline-first multi-master replication and conflict handling; compare with SQL+sync.
- [Phase TBD | Consideration] Create a platform-specific documentation section (credential storage, autostart, IPC, serial ports, packaging, etc.).
- [Phase TBD | Consideration] Raylib (or similar) client idea to complement TUI or desktop variants (e.g., graphical bandmap, spot heatmap, large-screen contest dashboard).

## Triaged (needs placement)
- (none)

## Moved to Roadmap/Docs
- API docs/tooling → Roadmap 1.5 REST + WebSocket Bridge.
- Cache strategy → Roadmap 1.2.5 Feature Flags and Cache Hooks.
- Callsign identifier imports → Roadmap 3.3 Callsign Identifier Imports.
