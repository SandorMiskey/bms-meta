# Data Layer Design (Draft)

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Overview
- Databases: SQLite and PostgreSQL.
- Migration tool: `golang-migrate` (external dependency; stdlib-preference exception).
- Maintain two migration sets: `db/migrations/sqlite` and `db/migrations/postgres`.
- Soft delete only (use `deleted_at` timestamps).

## Standard Library Preference
- Prefer Go standard library for implementation.
- Exceptions must be justified (e.g., `golang-migrate` for cross-DB migrations).

## Migration Strategy
- Tool: `golang-migrate` CLI, invoked via Makefile targets.
- Naming: timestamp-based migration files.
- Each migration should target only features common to SQLite and PostgreSQL.
- Keep `schema_migrations` aligned across both migration sets.

## SQL Layout
- Schemas: `db/schema/sqlite` and `db/schema/postgres`.
- Migrations: `db/migrations/sqlite` and `db/migrations/postgres`.
- Queries: split by DB and domain for readability:
  - `internal/storage/sqlite/read/<domain>`
  - `internal/storage/sqlite/write/<domain>`
  - `internal/storage/postgres/read/<domain>`
  - `internal/storage/postgres/write/<domain>`

## Core Tables (Draft)
- `users`
- `operators`
- `callsigns`
- `callsign_memberships`
- `stations`
- `operating_contexts`
- `log_entries`
- `contests`
- `contest_rulesets`
- `exchange_items`
- `rigs`
- `rig_profiles`
- `station_rigs`
- `callsign_history`
- `callsign_profiles`
- `qsl_status`
- `qsl_events`
- `auth_credentials`
- `auth_sessions`

## Access Control Tables (Draft)
- `callsign_memberships` (role: `admin` | `write` | `read`, created_by, created_at)
- `record_locks` (log_entry_id, locked_by, locked_at, reason, unlocked_by, unlocked_at)

## Locking Rules (Draft)
- Locks apply per log entry; they do not lock entire callsigns.
- `admin` can lock and unlock any record.
- `write` can edit unless a record is locked.
- Optional: allow `write` to lock own records when enabled by admin policy.

## Auth Tables (Draft)
- `auth_credentials` (user_id, password_hash, created_at, updated_at)
- `auth_sessions` (token, user_id, expires_at, refreshed_at, revoked_at)

## Types and Compatibility
- Prefer compatible types: `text`, `integer`, `real`, `blob`, `boolean` (SQLite alias).
- Avoid DB-native enums; use text enums with application validation.
- Use dual identifiers for core tables:
  - `internal_id` is the primary key (SQLite `INTEGER PRIMARY KEY`, PostgreSQL `BIGINT` identity).
  - `public_id` is a ULID stored as `TEXT` with a `UNIQUE` index.
  - Foreign keys always reference `internal_id`.
  - Sync/import flows use `public_id` and map to local `internal_id` before writing child rows.

## Indexing Strategy (Initial)
- `log_entries`: `(timestamp_utc)`, `(other_callsign)`, `(frequency_hz)`, `(mode_enum)`
- `exchange_items`: `(log_entry_id)`, `(field_key)`
- `qsl_status`: `(log_entry_id)`, `(channel)`, `(status)`
- `callsign_history`: `(callsign_id)`, `(last_seen)`
- `operating_contexts`: `(callsign_id)`, `(operator_id)`

## Soft Delete Policy
- Use `deleted_at` on user-visible data.
- Never hard-delete log entries in MVP.

## QSL Status and Events Model
- Use `qsl_events` for audit history and multi-source updates.
- Use `qsl_status` as the latest per-source snapshot for fast queries.
- `qsl_status` fields: `log_entry_id`, `source`, `status`, `sent_at`, `received_at`, `note`.
- `qsl_events` fields: `log_entry_id`, `source`, `status`, `event_time`, `note`, `created_by`.
- Sent and received are independent; a QSL may be received before sent.
- UI status should be derived from `sent_at` and `received_at`.
- Status enum: `unsent`, `sent`, `received`, `confirmed`.

## Notes
- Schema will evolve during implementation; update this document as needed.
