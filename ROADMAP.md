# BMS Project Plan

## How to Read This Plan
- The roadmap is organized by phases with ordered steps and sub-sections.
- Each sub-section includes explicit dependencies and risks to help sequencing.
- Raw ideas live in `IDEA-BACKLOG.md` and should be triaged into the roadmap or docs.
- The global Risks section summarizes cross-cutting issues.

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This planning document is licensed under Apache-2.0. Project components follow the dual-licensing model described in this plan: Apache-2.0 for open components and AGPL-3.0-or-Commercial for SaaS-critical components. All newly created or generated files must include a license header or SPDX identifier with the owner information above.

## Overview and Priorities
- Goal: a modern, client-server amateur radio logging platform for everyday and contest use.
- UI targets: TUI/CLI, web (local or remote), desktop (Tauri/Electron), mobile later.
- Primary focus: server plus TUI/CLI clients.
- Secondary focus: web UI and desktop app.
- Lowest priority: mobile app.
- Integrations: LoTW, QRZ.com, and Clublog (Clublog later phase).
- Server components can synchronize to remote instances for multi-site operation and backups.
- BMS Cloud planned for QRZ-like services plus off-site backup.
- Support contest operations like M/S and M/M multi-operator modes.
- Radio control via CAT/FLrig or native support.
- Open source with English documentation.
- Simple install: bundled local server + client; advanced install: independent components and remote servers.

## Technology Stack
### Server
- Go implementation with optional authentication and one-server/many-client usage.
- gRPC for server-to-server sync and TUI/CLI communication.
- WebSocket for browser/Tauri/Electron clients.
- REST API for integrations.
- SQLite by default (libSQL/Turso compatible), with optional remote PostgreSQL seeding and configuration.
- sqlc for typed DB access; migration tooling for SQLite/PostgreSQL.
- Modular monolith in MVP with microservice-container boundaries defined for later.
- htmx-compatible server endpoints.
- Lua-based plugin system for contest rules (UDC) and awards/statistics.
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
- iOS and Android support.
- Technology selection deferred.

## Repository Strategy
### Repo 1: `bms-core` (Go)
- Go module: `github.com/SandorMiskey/bms-core`.
- Scope: server, TUI/CLI, SDKs, proto definitions, plugin API, core data model.
- Suggested structure:
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
  - `packages/sdk` (generated TypeScript clients from `proto/` or REST)
  - `packages/config` (shared config parsing for web/desktop)

### Repo 3: `bms-website` (Project Website)
- Scope: public website and release information.
- Static site through Phase 4, SaaS-aligned site in Phase 5.
- English-only content.

## Licensing Strategy (Dual Licensing)
- Apache-2.0 components:
  - CLI/TUI
  - Web UI
  - SDKs/API clients
  - Protocol definitions
  - Plugin API
  - Base self-hosted server (single-user/single-station)
- Dual-licensed (AGPL-3.0-only or Commercial) components (`bms-cloud` repo):
  - Multi-tenant user management
  - Cloud sync
  - Cluster/spot/realtime feeds
  - Contest coordination services
  - AI/statistics services
  - Historical big-data pipelines
- Required actions:
  - Use SPDX header templates from `SPDX_Apache.txt` and `SPDX_AGPL.txt`.
  - Reference `LicenseRef-Commercial` from `LICENSE.md` for commercial builds.
  - Maintain AGPL/Commercial code in the `bms-cloud` repository with clear boundaries.
  - Ensure generated code includes SPDX headers or license banners.
  - Document licensing boundaries in `bms-meta/docs/licensing.md`.

## Key Dependencies
- Go: `google.golang.org/grpc`, `grpc-gateway` (REST), WebSocket library, `sqlc`.
- Database drivers: SQLite/libSQL, `pgx` for PostgreSQL.
- TUI/CLI: `charmbracelet/bubbletea`, `cobra`, config loader (e.g. `viper`).
- Lua runtime: `gopher-lua` or equivalent.
- Web: htmx, minimal TypeScript build tool (e.g. Vite).
- Contest data: DX cluster library, RBN integration tooling.
- Rig control: FLrig integration or native CAT drivers.

## Functional Scope
### Contest Operations
- Cluster support with DX cluster library, switching, monitoring, and new spot alerts.
- Highlight when the station is spotted; RBN support.
- Bandmap support.
- Callsign validation (N, N+1).
- Score calculation and prediction.
- Propagation data and multiplier tracking.
- SO2V, SO2R, 2BSIQ support.
- Multi-client operation on one server.
- CW support.
- Callsign metadata, history, expected exchange, club memberships.
- Cabrillo import/export support for contest workflows.
- RTC and contestonlinescore.com support.
- Statistics and AI tooling.

### Everyday Operations
- QRZ.com data display.
- LoTW integration (MVP).
- Clublog integration (later phase).
- DX Cluster and RBN integration for everyday mode.
- ADIF import/export support for normal logging.
- Awards (DXCC, WAS, WAZ) and statistics.
- CW support.
- Callsign metadata and history.
- Propagation data.
- DXpeditions data.

## Future Plans
- Digital modes (FTx) support.
- Remote operation support: keyer, UltraBeam, Station Master, etc.
- Winlink, APRS, and LoRa support.
- KYC for awards (LoTW-like), including client certificate issuance and mTLS identity for SaaS use.
- 2FA (authenticator app) and passkey support.
- Multiple saved login tokens with user selection.
- POTA/SOTA/IOTA support (including mobile).
- Additional log formats (e.g. DXLog.net, N1MM+, other SQLite-backed loggers).
- BMS Cloud:
  - Social network features.
  - QRZ.com-like services.
  - Local client with server hosted in cloud.
- Contest evaluation plugin (UBN).

## Risks and Mitigations
- Licensing complexity → early SPDX/NOTICE setup and component boundaries.
- QRZ/LoTW API terms → review terms, provide opt-in configuration.
- gRPC/WebSocket compatibility → clear API contracts and generated clients.
- Cross-platform packaging (Tauri/Electron) → isolate platform-specific code.
- Plugin security (Lua) → sandboxing and permission model.
- Multi-client concurrency → DB migrations + locking strategy, load tests.
- Rig control integration → staged support with FLrig before native CAT.
- Phase-specific risks and dependencies are documented in the roadmap sections for each phase.

## Iterative Implementation Roadmap
### Phase 0: Foundation and Licensing
#### 0.1 Licensing Boundaries and Artifacts
Status: completed (2026-01-17)
1. Create a component-to-license matrix for core vs SaaS-critical modules (`bms-cloud` repo for AGPL/Commercial).
2. Confirm AGPL variant as `AGPL-3.0-only` and update all references accordingly.
3. Adopt SPDX templates from `SPDX_Apache.txt` and `SPDX_AGPL.txt` plus `LICENSE.md` commercial note.
4. Define SPDX header placement rules for Go, SQL, proto, Lua, and config files.
5. Draft `LICENSE-APACHE`, `LICENSE-AGPL`, `COMMERCIAL_LICENSE.md`, and `NOTICE` placeholders.
6. Publish `bms-meta/docs/licensing.md` explaining dual-licensing, commercial builds, and repo split.
7. Dependency: final confirmation of repo separation for AGPL/Commercial components.
8. Risk: SPDX inconsistencies or boundary shifts require repo refactors.

#### 0.2 Repository Bootstrap
Status: completed (2026-01-17)
1. Initialize `bms-core` repo structure and `go.mod`.
2. Defer CI; use manual build workflows with Makefiles initially.
3. Add `.gitignore`, `configs/`, `deploy/`, and `docs/` scaffolding for later phases.
4. Establish code generation layout (`gen/`) and ownership rules.
5. Define versioning rules for APIs and database migrations (timestamp).
6. Dependency: licensing structure ready to apply headers to new files.
7. Risk: early CI assumptions diverge from final toolchain.

#### 0.3 Configuration and Runtime Model
Status: completed (2026-01-17)
1. Define server config schema (DB, auth, logging, integrations, plugins).
2. Define client config schema (server endpoint, auth, themes, keymaps).
3. Specify precedence rules for local vs server-supplied config.
4. Create example config templates for local-only and remote modes.
5. Dependency: core domain model for required config fields.
6. Risk: config precedence changes causing client/server drift.

#### 0.4 Core Domain Model
Status: completed (2026-01-17)
Note: the domain model is a living document and will evolve during implementation.
1. Define logbook entry fields (callsign, band, mode, timestamps, exchange, RST, grid, etc.).
2. Define station/operator entities and relationships.
3. Define contest metadata, history, and expected exchange entities.
4. Define rig/CAT metadata models and future extension points.
5. Dependency: requirements from contest and everyday workflows.
6. Risk: schema expansion later creates migration churn.

#### 0.5 Data Layer Design
Status: completed (2026-01-17)
1. Create SQLite/PostgreSQL schema with migrations, seeds, and indexing strategy.
2. Define `sqlc` query layout and naming conventions.
3. Outline migration runner strategy and rollback expectations.
4. Dependency: finalized core domain model.
5. Risk: SQLite/Postgres feature mismatches or migration rollback gaps.

#### 0.6 API Contracts
Status: completed (2026-01-17)
1. Draft proto packages for logbook, station config, auth, sync, and events.
2. Define versioning rules and backward compatibility expectations.
3. Specify event stream payloads for multi-client synchronization.
4. Dependency: data layer schema and config model.
5. Risk: early contract changes ripple to clients.

#### 0.7 Service Boundaries and Extensibility
Status: completed (2026-01-17)
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Define service boundaries aligned to future microservice split (logbook, auth, integrations, sync).
3. Map container boundaries to `deploy/` layouts and runtime dependencies.
4. Prototype Lua plugin host scaffolding: discovery, config, sandbox assumptions, and lifecycle hooks.
5. Dependency: baseline repo layout and configuration model.
6. Risk: service boundary changes later increase refactor cost.

### Phase 1: MVP (Server + TUI/CLI)
#### 1.1 Database and Storage
##### 1.1.1 Requirements and Scope
Status: completed (2026-01-21)
- Review `IDEA-BACKLOG.md` and the Future Plans section for MVP schema needs.
- Decide MVP table list, ID strategy, timestamps, soft delete policy, and naming rules.
- Adopt dual IDs for core tables (internal int64 PK + public ULID), with sync using public IDs and local mapping.
- Standardize audit columns (`created_at`, `created_by_user_id`, `updated_at`, `updated_by_user_id`, `deleted_at`) on core tables.
- Record extension assumptions to avoid schema churn.

##### 1.1.2 Database Strategy
Status: completed (2026-01-21)
- Define SQLite-first baseline with optional PostgreSQL seeding.
- Confirm migration tooling (golang-migrate), rollback expectations, and versioning.
- Require lowest-common-denominator SQL, with documented exceptions only.
- Enforce transactional migrations where supported and require down migrations.
- Document SQL dialect boundaries to avoid drift.

##### 1.1.3 Schema Draft
- Draft core tables and relations: users, callsigns, memberships, logbook_entries, stations, rigs, nodes, audit_events, qsl_events, qsl_status.
- Capture minimal fields and note forward-compat columns.
- Define dual ID columns (`internal_id` + `public_id`) and FK usage for each core table.
- Specify ownership rules (callsign memberships, station ownership XOR, operator fields).
- Add lookup tables for bands and modes.
- Add DXCC entities/prefixes with validity windows and replacement mapping.
- Decide lookup tables or enums for contests.

##### 1.1.4 Migration Layout
- Create migration directories for sqlite and postgres.
- Add baseline up/down migrations with SPDX headers.
- Define naming rules for future migrations.

##### 1.1.5 sqlc Layout
- Define query structure under `internal/storage` with read/write split.
- Map ownership to services (auth, logbook, contest, integrations).
- Decide naming and output package layout rules.

##### 1.1.6 Indexes and Constraints
- Add MVP indexes for callsign, band, mode, and timestamp.
- Add FK and uniqueness constraints for integrity.
- Validate parity across sqlite and postgres.

##### 1.1.7 Documentation and Checks
- Record migration commands and bootstrap steps.
- Document schema decisions and limitations.
- Validate SQLite-first default and basic Postgres seeding path.

Dependency: Phase 0 schema and sqlc layout.
Risk: migration rollback issues or SQL dialect drift.

#### 1.2 Server Runtime
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Implement config loader and validation with sane defaults.
3. Add structured logging, health checks, and graceful shutdown.
4. Wire DB connections and connection pooling.
5. Implement feature flags for optional auth and integrations.
6. Dependency: configuration model and logging guidelines from Phase 0.
7. Risk: config validation gaps cause runtime failures.

#### 1.3 Authentication and Sessions
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Implement optional login (user/password) with session token issuance.
3. Add token refresh with rotation before expiry (MVP).
4. Support local-only default while allowing auth enablement.
5. Enforce role-less access for MVP, with hooks for future RBAC.
6. Dependency: config model and gRPC auth interceptors.
7. Risk: auth bypass pathways leak into remote mode.

#### 1.4 gRPC + Sync
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Implement gRPC services for logbook CRUD/search, station config, metadata, and history.
3. Add event stream for multi-client updates and change notifications (client-server only in MVP).
4. Validate compatibility with TUI/CLI clients.
5. Dependency: stable proto contracts and data layer behavior.
6. Risk: event ordering or idempotency issues in sync.

#### 1.5 REST + WebSocket Bridge
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Provide minimal REST gateway for integrations and future web/desktop.
3. Add WebSocket bridge for events and live updates.
4. Document API endpoints and error codes.
5. Dependency: gRPC services and event stream stability.
6. Risk: REST/WebSocket divergence from gRPC semantics.

#### 1.6 ADIF and Data Import/Export
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Implement ADIF import pipeline for normal logging (MVP).
3. Implement ADIF export and CSV export for backups.
4. Add LoTW integration for MVP (upload/download basics).
5. Add round-trip tests for common ADIF fields.
6. Dependency: finalized logbook field mapping.
7. Risk: incomplete ADIF mapping causes data loss.

#### 1.7 TUI/CLI Core UX
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Implement server connection flow and status panel.
3. Implement log list view with filtering/search.
4. Implement new/edit entry forms and validation.
5. Implement sync status, theme switching, and keymap support.
6. Add CLI commands for import/export and basic health checks.
7. Dependency: stable gRPC APIs and theme/keymap spec.
8. Risk: UX churn if API shapes change.

#### 1.8 Packaging and Docs
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Create simple local install bundle (server + CLI + config).
3. Provide default config and sample dataset.
4. Write MVP docs: quickstart, config reference, backup/restore workflow.
5. Dependency: stable CLI flags and config formats.
6. Risk: packaging complexity across OS targets.

#### 1.9 Website Bootstrap (post-MVP)
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Finalize product/package name and service name (BMS is placeholder; target BMS-derived naming).
   - Reminder: BMS should be GNU-like abbreviation based on HA5BMS, e.g. "BMS Management Suite/Stack", "Band Management Suite/Stack", or "Broadcast Management Suite".
3. Finalize website domain and branding (name lock-in after website launch and package publication).
4. Create separate `bms-website` repository.
5. Choose static site tooling (Phase 4 uses static output).
6. Publish minimal landing page with MVP quickstart and docs links.
7. Dependency: MVP user flows, documentation readiness, and name/domain decisions.
8. Risk: site content drift from product behavior; post-launch renaming constraints.

### Phase 2: Minimal Web/Desktop Client
#### 2.1 Web UI Foundations
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Define minimal UI architecture aligned with htmx and server-rendered templates.
3. Build core logbook views: list, detail, create/edit, search/filter.
4. Implement WebSocket client for live updates and sync notifications.
5. Add authentication flow and session handling for remote servers.
6. Implement Neovim-style keybindings and theme switching.
7. Add config loader (local and server-provided overrides).
8. Dependency: stable REST/WebSocket API and auth flow from Phase 1.
9. Risk: real-time UI inconsistency if event stream semantics drift.

#### 2.2 Desktop Packaging
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Choose desktop wrapper (Tauri or Electron) and define constraints.
3. Implement desktop shell with shared web UI bundle.
4. Wire deep-linking, file import dialogs, and offline/online indicators.
5. Add local server auto-start option for bundled installs.
6. Dependency: packaging decision (Tauri/Electron) and shared web build pipeline.
7. Risk: platform-specific packaging issues and auto-update complexity.

#### 2.3 Shared UI Assets
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Create shared theme tokens aligned to TUI themes.
3. Centralize keybinding definitions and documentation.
4. Build a small UI component library for forms and tables.
5. Dependency: finalized theme/keymap spec from Phase 1.

#### 2.4 Website Update
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Add web/desktop feature highlights and screenshots.
3. Document keybindings and theme parity with TUI.
4. Update web/desktop onboarding steps.
5. Dependency: finished web/desktop MVP flows.
6. Risk: outdated screenshots as UI evolves.

### Phase 3: Integrations and Plugins
#### 3.1 DX Cluster and RBN Integration
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Integrate DX Cluster and RBN feeds for normal and contest modes (external services).
3. Provide shared feed normalization for clients.
4. Long-term: optional BMS core cluster feed streaming for clients.
5. Dependency: event stream and integration config.
6. Risk: third-party feed availability and rate limits.

#### 3.2 QRZ and Clublog Integrations (Later)
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Add QRZ.com lookup integration (callsign details, caching).
3. Define Clublog integration boundary for later phase.
4. Dependency: API key management and rate-limiting support.
5. Risk: third-party ToS limits or API availability changes.

#### 3.3 Plugin System
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Implement Lua plugin host runtime (loading, sandbox rules, lifecycle).
3. Provide plugin API for awards and contest rules.
4. Add plugin configuration schema and examples.
5. Dependency: stable core domain model and event hooks.
6. Risk: plugin sandbox escapes or unsafe plugin defaults.

#### 3.4 Rig Control
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Implement FLrig integration and basic CAT control interfaces.
3. Define extension points for native CAT drivers later.
4. Dependency: rig metadata model and config schema.
5. Risk: device compatibility variance and platform-specific drivers.

#### 3.5 Website Update
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Document QRZ/LoTW integrations and opt-in configuration.
3. Publish plugin developer overview and stability notes.
4. Add integration setup guides.
5. Dependency: integration docs and plugin API references.
6. Risk: third-party terms changes require rapid edits.

### Phase 4: Contest Features
#### 4.1 Cluster and Spotting
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Use shared DX Cluster/RBN feed to drive contest spotting (from Phase 3).
3. Add new spot notifications and "spotted us" indicators.
4. Add RBN feed ingestion.
5. Dependency: reliable event stream and cache layer.
6. Risk: high-volume feed load impacting latency.

#### 4.2 Contest Workflow
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Implement bandmap with filters and multipliers.
3. Add callsign validation (N, N+1) and duplicate checking.
4. Implement score calculation and prediction.
5. Add propagation data overlays.
6. Add multiplier tracking and exchange validation.
7. Dependency: contest metadata models and QSO history APIs.
8. Risk: scoring ruleset complexity across contests.

#### 4.3 Multi-Operator Support
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Enable SO2V, SO2R, 2BSIQ workflows and UI controls.
3. Improve real-time sync to support multi-operator contesting.
4. Dependency: low-latency sync and conflict resolution.
5. Risk: state conflicts in multi-operator editing.

#### 4.4 Contest Reporting and Analytics
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Integrate RTC and contestonlinescore.com reporting.
3. Add Cabrillo import/export for contest submissions.
4. Expand contest metadata, history, and expected exchange models.
5. Add statistics and AI tooling for rate analysis and performance hints.
6. Dependency: stable scoring engine and historical data retention.
7. Risk: external score reporting downtime.

#### 4.5 Website Update
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Publish contest feature matrix (cluster, bandmap, SO2R/SO2V, scoring).
3. Document contest reporting integrations and operational guidance.
4. Add performance and contest workflow tips.
5. Dependency: finalized contest features and screenshots.
6. Risk: contest-specific updates lag feature delivery.

### Phase 5: SaaS-Critical Services (Dual Licensed)
#### 5.1 Multi-Tenant Platform
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Build multi-tenant user management and isolated data storage.
3. Implement cloud sync pipelines and replication controls.
4. Deliver admin operations for tenant lifecycle.
5. Dependency: `bms-cloud` repo and tenant isolation model.
6. Risk: licensing boundary drift between repos.

#### 5.2 Realtime Feeds and Coordination
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Aggregate cluster/spot feeds and distribute to tenants.
3. Implement contest coordination services for team/multi-site operation.
4. Dependency: scalable streaming infrastructure.
5. Risk: high traffic bursts requiring autoscaling.

#### 5.3 Data and AI Services
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Build historical data ingestion and storage pipelines.
3. Implement AI/statistics services for long-term insights.
4. Add a RAG AI assistant for product usage support and general amateur radio questions (curated knowledge base).
5. Deliver BMS Cloud foundation for QRZ-like services.
6. Dependency: data retention policy and telemetry pipeline.
7. Risk: data privacy and compliance concerns.

#### 5.4 Website Transition
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Transition from static site to SaaS-aligned website.
3. Add commercial licensing and contact flows.
4. Publish BMS Cloud service descriptions and onboarding.
5. Dependency: SaaS MVP readiness and commercial offering definition.
6. Risk: marketing/commercial content outpaces product readiness.

### Phase 6: Future Extensions
#### 6.1 Digital Modes and Remote Control
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Add digital mode (FTx) integration support.
3. Add remote operation support for keyer, UltraBeam, Station Master, etc.
4. Dependency: hardware integration APIs and streaming infrastructure.
5. Risk: vendor protocol changes and device availability.

#### 6.2 Additional Integrations
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Add Winlink, APRS, and LoRa integrations.
3. Add KYC and blockchain-backed award verification.
4. Add SaaS-only client certificates with mTLS identification.
5. Provide a standalone ADIF uploader (CLI + mini desktop) using certificates.
6. Add certificate-based ADIF upload support to the main CLI.
7. Dependency: external service agreements and regulatory requirements.
8. Risk: KYC requirements changing across regions.

#### 6.3 Mobile and Outdoor Operation
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Add POTA/SOTA/IOTA workflows and awards.
3. Deliver mobile client support and sync.
4. Add on-the-air activity support with activity-based awards (details TBD, hamaward.cloud-style).
5. Dependency: stabilized web API and offline sync design.
6. Risk: mobile offline/online state complexity.

#### 6.4 Contest Evaluation
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Implement contest evaluation plugin (UBN).
3. Ensure contest organizers can run events with log upload, evaluation, and result publication workflows.
4. Dependency: stable contest log export format.
5. Risk: contest-specific rule variants.

#### 6.5 Website Update
1. Review `IDEA-BACKLOG.md` and the Future Plans section for items to incorporate.
2. Update roadmap for digital modes, remote ops, mobile, and outdoor workflows.
3. Publish status of POTA/SOTA/IOTA and mobile progress.
4. Dependency: updated roadmap milestones.
5. Risk: roadmap commitments diverge from delivery.
