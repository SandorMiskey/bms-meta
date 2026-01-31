## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Roadmap Overview
- This roadmap is outcome-focused and ordered by dependencies, not calendar dates.
- Architecture decisions are documented in `ARCHITECTURE.md`.
- Execution steps and micro-steps live in `EXECUTION-PLAN.md`.

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

## Outcome Phases (Dependency Order)
### Phase 0: Foundation and Licensing (completed)
- Define licensing boundaries and repo split for open vs SaaS-critical components.
- Establish repo bootstrap, configuration model, core domain model, and schema design.
- Draft API contracts and service boundaries for future extensibility.

### Phase 1: MVP (Server + TUI/CLI) (in_progress)
- Deliver the core database, migrations, and typed access.
- Implement server runtime foundations (config, logging, diagnostics, auth).
- Provide gRPC services, REST/WebSocket bridge, and sync.
- Support ADIF import/export and the MVP logbook UX in TUI/CLI.
- Package a local install bundle and publish MVP documentation.

### Phase 2: Minimal Web/Desktop Client (planned)
- Build a minimal web UI aligned with htmx server-rendered templates.
- Package desktop wrapper with shared web UI.
- Provide shared themes, keybindings, and UI components.
- Update website with web/desktop onboarding.

### Phase 3: Integrations and Plugins (planned)
- Integrate DX Cluster/RBN and QRZ/Clublog services.
- Add identifier imports and plugin system foundation.
- Implement rig control via FLrig and define native CAT extension points.

### Phase 4: Contest Features (planned)
- Deliver contest workflow features (bandmap, scoring, multipliers, spotting).
- Enable multi-operator workflows and contest reporting integrations.
- Publish contest feature matrix and guidance.

### Phase 5: SaaS-Critical Services (planned)
- Build multi-tenant BMS Cloud foundations and realtime coordination.
- Add data/AI services and SaaS-aligned website transition.

### Phase 6: Future Extensions (planned)
- Add digital mode and remote control integrations.
- Expand integrations (Winlink/APRS/LoRa) and mobile clients.
- Implement contest evaluation workflows (UBN).

## Functional Scope (Outcome Summary)
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
