## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Purpose
This document records stable architecture decisions and constraints for BMS. It
describes system structure, technology choices, integration boundaries, and
operational principles. Implementation steps live in `EXECUTION-PLAN.md`, and
outcome-level sequencing lives in `ROADMAP.md`.

## System Overview
- Core runtime: `bms-core` server with modular services (auth, logbook, contest,
  integrations, sync) in a modular monolith boundary for MVP.
- Entry points: `bmsd` (server) and `bms` (TUI/CLI) with shared config/logging.
- Client surfaces: TUI/CLI, web UI (htmx-oriented), desktop wrapper (Tauri/Electron).
- Integration surfaces: gRPC (sync + internal APIs), REST (external integrations),
  WebSocket (client updates).
- Background workflows: config resolution/validation, migration checks, sync,
  integration ingestion, cache refresh, and scheduled exports.
- Extensibility: Lua plugin system for contest rules and awards with sandboxing.

## Technology Stack
### Server
- Go implementation with optional authentication and one-server/many-client usage.
- gRPC for server-to-server sync and TUI/CLI communication.
- WebSocket for browser/Tauri/Electron clients.
- REST API for integrations.
- SQLite by default (libSQL/Turso compatible), optional PostgreSQL seeding.
- `sqlc` for typed DB access; migration tooling for SQLite/PostgreSQL.
- Modular monolith in MVP with defined microservice boundaries for later.
- htmx-compatible server endpoints.
- Lua-based plugin system for contest rules and awards/statistics.
- ADIF import/export and other log formats.
- macOS, Linux, *BSD, Windows support.
- CAT/rig control via FLrig or native implementations.

### TUI/CLI
- Go + BubbleTea.
- Local or remote server connections.
- Neovim-style keybindings and theming.
- Lua-based configuration and plugins.
- Configuration can be sourced from server or local files.

### Web UI
- Minimal JS/TS framework with htmx for HTML-driven UI.
- Local or remote server connections.
- WebSocket for real-time updates.
- CSS themes aligned with Neovim palette conventions.
- Neovim-style keybindings.
- Neovim-like configuration and plugins (Lua if feasible).

### Desktop
- Web UI wrapped with Tauri or Electron.
- Local or remote server connections.
- Shared theming and keybindings with web UI.
- Neovim-like configuration and plugins (Lua if feasible).
- Configuration can be sourced from server or local files.

### Mobile (Future)
- Connect to remote server or BMS Cloud account.
- iOS and Android support; technology selection deferred.

## Repository Strategy
### Repo 1: `bms-core` (Go)
- Go module: `github.com/SandorMiskey/bms-core`.
- Scope: server, TUI/CLI, SDKs, proto definitions, plugin API, core data model.
- Structure:
  - `cmd/bmsd` (server)
  - `cmd/bms` (TUI/CLI)
  - `internal/` (services: auth, logbook, contest, integrations, sync)
  - `pkg/` (shared SDK/clients)
  - `proto/` (gRPC definitions)
  - `db/schema` + `db/migrations`
  - `plugins/` (Lua runtime assets)
  - `configs/` (default config templates)
  - `deploy/` (container definitions and release artifacts)
  - `docs/` (English documentation)

### Repo 2: `bms-client` (Web/Desktop)
- Scope: web UI and desktop app sharing a single UI codebase.
- Suggested structure:
  - `apps/web` (browser UI)
  - `apps/desktop` (Tauri/Electron wrapper)
  - `packages/ui` (shared UI components + themes)
  - `packages/sdk` (generated TypeScript clients)
  - `packages/config` (shared config parsing for web/desktop)

### Repo 3: `bms-website` (Project Website)
- Scope: public website and release information.
- Static site through Phase 4, SaaS-aligned site in Phase 5.
- English-only content.

## Data Handling
- SQLite is the default storage engine for local-first installs.
- PostgreSQL is supported for optional remote seeding and larger deployments.
- Schema parity between SQLite and PostgreSQL is required; migrations must be
  reversible where possible and use lowest-common-denominator SQL.
- `sqlc` is used for typed access; raw SQL in services is avoided.
- External storage systems are deferred for MVP; future phases may add object
  storage for large assets or data lakes for analytics.

## Document Generation Principles
- Generated outputs (schema dumps, API docs, SDKs) must be reproducible and
  deterministic, with a clear source of truth.
- Generated files should include SPDX headers or license banners when applicable.
- Generated artifacts live in dedicated directories (`db/schema`, `gen/`, `docs/`).
- Avoid manual edits to generated outputs; regenerate instead.

## Integration Strategy
- External integrations (LoTW, QRZ.com, Clublog, DX Cluster, RBN) are opt-in and
  rate-limited; credentials are stored in env vars or keychain when available.
- Integration data is treated as untrusted input; validate and normalize at
  boundary layers before it reaches core services.
- Automation via external tools (e.g., n8n) must validate payloads, enforce
  allowlists, and never log secrets.

## Internationalization (i18n)
- English is the canonical language for documentation and error messages.
- UI strings should be externalizable (keyed) to allow later localization.
- UTF-8 is the required encoding across all layers.

## Security and Operations Principles
- Enforce TLS for remote connections when enabled.
- Authentication is optional, but secure defaults must be provided.
- Rate-limit external integrations and validate all user input.
- Redact secrets in logs; internal packages must not log directly.
- Use least-privilege DB users and avoid logging credentials or tokens.
- Prefer structured logging with stable fields and consistent formatting.

## Licensing and Boundary Rules
- Apache-2.0 components: CLI/TUI, web UI, SDKs, protocol definitions, plugin API,
  base self-hosted server.
- AGPL-3.0-only or Commercial components (`bms-cloud`): multi-tenant user
  management, cloud sync, realtime feeds, contest coordination services, AI.
- Use SPDX templates from `SPDX_Apache.txt` and `SPDX_AGPL.txt` and reference
  `LicenseRef-Commercial` for commercial builds.

## Operational Risks and Mitigations
- Licensing complexity: enforce SPDX/NOTICE and repo boundaries early.
- QRZ/LoTW API terms: review ToS and provide opt-in configuration.
- gRPC/WebSocket compatibility: keep API contracts explicit and versioned.
- Cross-platform packaging (Tauri/Electron): isolate platform-specific code.
- Plugin security: sandbox Lua and restrict file/network access by default.
- Multi-client concurrency: plan for DB locking and load tests.
- Rig control integration: stage FLrig support before native CAT drivers.
