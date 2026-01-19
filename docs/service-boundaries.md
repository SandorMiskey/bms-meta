# Service Boundaries and Extensibility (Draft)

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Purpose
- Define logical service boundaries for a container-ready monolith.
- Avoid microservice sprawl; split only when justified.
- Prepare for future extraction without forcing it in MVP.

## MVP Service Boundaries
- Logbook (CRUD, search, metadata)
- Station/Operator (profiles, operating context)
- Config (server-provided defaults + local merge)
- Integrations (ADIF + LoTW in MVP, others later)
- Sync/Events (client-server only in MVP)
- Auth (optional login, user/password, token-based)

## Data Ownership Matrix (Draft)
| Service | Owned data |
| --- | --- |
| Logbook | log_entries, exchange_items, qsl_status, qsl_events, callsign_history, callsign_profiles |
| Station/Operator | users, operators, callsigns, callsign_memberships, operating_contexts, stations, rigs, rig_profiles, station_rigs |
| Config | server_config defaults, client overrides (if persisted) |
| Integrations | integration credentials, sync state (LoTW, ADIF) |
| Sync/Events | event stream checkpoints, client subscriptions |
| Auth | sessions, tokens (future) |

## Storage Boundaries (Recommended)
- Use `internal/storage/<db>/<read|write>/<service>` to align storage with ownership.
- Cross-service writes should go through the owning service.
- Keep queries compatible across SQLite/PostgreSQL when shared.

## Auth (MVP)
- Provide user/password login and token issuance.
- Rotate tokens before expiry; local-only default.
- Auth is optional but supported in MVP.

## Sync and Events (MVP)
- Client-server sync and event stream only.
- Server-server sync is deferred but must not be blocked by design.

## Integrations (MVP)
- ADIF import/export for normal logging.
- LoTW upload/download basics.
- QRZ/Clublog deferred to later phases.

## Lua Plugin Host
- Discovery: scan plugin directory.
- Lifecycle: load -> init -> run -> shutdown.
- Sandbox: file/network blocked by default; whitelist per admin policy.

## Container Dependencies (Draft)
- Database: SQLite or PostgreSQL.
- External services: LoTW (MVP), DX Cluster/RBN (Phase 3).
- SaaS-only: client certificates and mTLS (future).
- Runtime: Lua for plugins.

## Deferred Items (Summary)
- 2FA (authenticator app, passkey) and multi-token selection.
- Server-server sync.
- QRZ/Clublog integrations.

## Container Readiness
- Single server binary with clear internal boundaries.
- Container layouts aligned to `deploy/` but no microservice split in MVP.
