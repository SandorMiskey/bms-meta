# API Contracts (Draft)

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Overview
- Domain-specific proto packages with a shared common package.
- REST endpoints are 1:1 with gRPC services.
- Pagination uses cursor tokens (`page_size`, `page_token`).
- Event delivery uses a single stream per client with typed events.
- Errors use gRPC status plus structured `ErrorInfo` payloads.

## Proto Packages
- `bms.common.v1`
- `bms.logbook.v1`
- `bms.station.v1`
- `bms.auth.v1`
- `bms.sync.v1`
- `bms.events.v1`
- `bms.contest.v1` (later phase)

## MVP Services
- `Logbook`
- `Station`
- `Auth` (optional login + token-based sessions)
- `Sync`
- `Events`

## REST Mapping
- REST gateway mirrors gRPC RPCs and resource names 1:1.
- Versioning follows package names and URL prefix (e.g. `/v1/logbook`).
- All external identifiers use `public_id` (ULID); internal numeric IDs are never exposed.

## Pagination
- Requests accept `page_size` and `page_token`.
- Responses return `next_page_token` when more results exist.

## Event Stream
- Single bidirectional stream per client.
- Event payloads include `event_type`, `timestamp_utc`, `payload`.
- Event ordering is per-stream; clients must handle idempotency.

## Error Model
- Standard gRPC status codes for transport-level errors.
- Structured `ErrorInfo` message for application-level errors:
  - `code` (string)
  - `message` (string)
  - `fields` (key/value map)

## Authorization Model (Draft)
- Role-based access: `admin`, `write`, `read` scoped to callsigns.
- `admin` can grant/revoke roles; `write` can edit unless records are locked.
- `read` is view-only.
- Locked records reject write operations unless unlocked by an admin.

## Auth Sessions (Draft)
- Login with user/password returns a session token.
- Refresh rotates tokens before expiry.
- Logout revokes the current token.

## Identifiers
- External APIs accept and return `public_id` only.
- Internal numeric identifiers are never exposed.
- Default operator callsign comes from `users.default_callsign_id`.

## QSL Events (Draft)
- QSL updates should emit events with `source` and `status`.
- Sent and received are independent; a QSL may be received before sent.
- Internal QSL events are generated when matching in-system QSOs are detected.

## Compatibility Rules
- Additive fields are backward compatible.
- Breaking changes require new package version (e.g. `v2`).
- Deprecated fields must be documented and kept until v2.

## Notes
- Contest services are defined in this document but implemented later (Phase 4).
