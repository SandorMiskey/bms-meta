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

## Naming and Provenance
- Table names are plural and `snake_case`.
- Core tables include `internal_id`, `public_id`, `created_at`, `created_by_user_id`, `updated_at`, `updated_by_user_id`, `deleted_at`.
- `created_by_user_id` and `updated_by_user_id` always reference `users`; seed/automation uses a reserved `system` user.
- Store timestamps in UTC.

## Migration Strategy
- Tool: `golang-migrate` CLI, invoked via Makefile targets.
- Naming: timestamp-based migration files.
- Each migration should target only features common to SQLite and PostgreSQL.
- Keep `schema_migrations` aligned across both migration sets.
- Migrations should run inside a transaction when supported by the database.
- Every migration must provide a `down` rollback.
- Schema parity between SQLite and PostgreSQL is required; exceptions must be documented.

## SQL Layout
- Schemas: `db/schema/sqlite` and `db/schema/postgres`.
- Migrations: `db/migrations/sqlite` and `db/migrations/postgres`.
- Queries: split by DB and domain for readability:
  - `internal/storage/sqlite/read/<domain>`
  - `internal/storage/sqlite/write/<domain>`
  - `internal/storage/postgres/read/<domain>`
  - `internal/storage/postgres/write/<domain>`

## Core Tables (Draft)
- `users`: user accounts, defaults, and preferences.
- `callsigns`: licensed callsign records with DXCC and zone defaults.
- `callsign_memberships`: user-to-callsign roles and access.
- `callsign_identifiers`: imported callsign identifiers from external datasets.
- `stations`: station profiles, QTH metadata, and per-station overrides.
- `station_callsigns`: mapping of stations to allowed callsigns.
- `logbook_entries`: QSO log records and operator metadata.
- `rig_types`: equipment categories (radio, amp, antenna, etc.).
- `rigs`: individual equipment items owned by users or callsigns.
- `station_rigs`: mapping of rigs installed at stations.
- `nodes`: origin node metadata for audit and sync.
- `audit_events`: append-only audit trail for core entities.
- `qsl_status`: latest per-source QSL state snapshots.
- `qsl_events`: QSL event history records.
- `auth_credentials`: stored credentials for optional auth.
- `auth_sessions`: session tokens and expiry tracking.
- `dxcc_entities`: DXCC entity definitions with validity windows.
- `dxcc_prefixes`: prefixes associated with DXCC entities.

## Lookup Tables (Draft)
- `bands`: band definitions for log entries and validation.
- `modes`: mode definitions for log entries and validation.
- `rig_models`: known manufacturer/model templates for rig selection.
- Bands and modes are seeded from a reference data pack and may include scoped custom entries.

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

## Ownership and Membership (Draft)
- `callsign_memberships` binds users to callsigns with a role (`admin`, `write`, `read`).
- `callsign_memberships` includes invite tracking, role source, and optional notes.
- The creator of a callsign is inserted as the first `admin` membership.
- `stations` are owned by either a user or a callsign (not both); enforce via a check constraint.
- `station_callsigns` links stations to allowed callsigns; users can log with a station only if they hold the callsign membership.
- `logbook_entries` reference `callsign_id`, `created_by_user_id`, `operator_user_id`, and `operator_callsign_id`.
- `logbook_entries.station_id` is optional.

## Callsign Memberships (Draft)
- `role` stores `admin`, `write`, or `read`.
- `role_source` records how the role was assigned (e.g., `admin_grant`, `invite_accept`, `system_bootstrap`, `sync_import`).
- `note` stores optional admin comments.
- `invited_by_user_id` links to the inviter when applicable.
- `accepted_at` and `revoked_at` track membership lifecycle events.
- `revoked_by_user_id` records who revoked access.
- `created_at` acts as the invite timestamp; no separate `invited_at` is required.
- Enforce unique active membership on `(callsign_id, user_id)` with a partial unique constraint.

## Stations (Draft)
- `name` is unique per owner (user or callsign).
- `registered_qth` stores the station QTH used for licensing (optional).
- `grid_locator` stores the station grid square (optional).
- `latitude` and `longitude` store geolocation (optional).
- `itu_zone` and `cq_zone` override callsign defaults (optional).
- `sota_ref`, `pota_ref`, `wwff_ref`, and `iota_ref` store optional awards references.
- `notes` stores optional station notes.
- `is_active` disables a station without deleting data.

## Station Callsigns (Draft)
- `station_callsigns` links stations to callsigns that may use them.
- `is_primary` marks the default station for a callsign.
- Enforce unique active mapping on `(station_id, callsign_id)` with a partial unique constraint.
- Enforce one primary station per callsign in application logic.

## Users (Draft)
- `username` is the login identifier (unique).
- `email` is optional and can be used for notifications.
- `display_name` is the friendly label shown in UIs.
- `default_callsign_id` selects the operator callsign used by default.
- `default_station_id` selects the station used by default.
- `is_active` disables a user without deleting data.
- `is_system` marks reserved system accounts.
- `last_login_at` tracks the last login time.
- `email_verified_at` tracks email verification status.
- `timezone` and `locale` support user display preferences.

## Callsigns (Draft)
- `callsign` is stored in canonical uppercase and is unique for active rows (partial unique with soft delete).
- `registered_qth` stores the licensed QTH on the callsign (optional).
- `dxcc_entity_id` references the DXCC entity.
- `itu_zone` and `cq_zone` store default zones and can be overridden by station data.
- `is_active` disables a callsign without deleting data.

## Callsign Identifiers (Draft)
- `callsign_identifiers` stores identifiers from external datasets (10-10, CWops, FOC, A1, CWJF, HACWG, SKCC).
- Each row includes `identifier_type`, `identifier_value`, and `source` metadata.
- Identifiers can be snapshotted into logbook entries when present.

## DXCC (Draft)
- `dxcc_entities` stores DXCC entities with validity windows (`valid_from`, `valid_to`).
- `deleted_at` indicates soft deletion while preserving references.
- `replaced_by_entity_id` points to the successor entity when `valid_to` is set.
- `dxcc_prefixes` stores multiple prefixes per entity, with optional validity windows.

## Zone and Award Mapping (Draft)
- ITU/CQ zone mapping should be derived from prefix rules with validity windows.
- IOTA data sources are TBD; store IOTA references on stations and logbook entries for now.
- Mapping rules will be added as dedicated tables once data sources are finalized.

## Rig Inventory (Draft)
- `rig_types` defines equipment categories with stable codes and display names.
- `rig_models` stores known manufacturer/model templates for auto-fill.
- `rigs` are owned by either a user or a callsign (not both) and are mapped to stations via `station_rigs`.
- `rigs.rig_type_id` should be set; use a fallback `other` type when needed.
- `station_rigs.is_primary` can mark the default rig per type for a station.
- Enforce one primary rig per station and type in application logic.

## Rig Types (Draft)
- `code` is a stable category key (e.g., `radio`, `amp`, `antenna`, `other`).
- `name` is the display label.
- Standard audit fields apply.

## Rig Models (Draft)
- `manufacturer` and `model` identify the known template.
- `rig_type_id` optionally links the template to a category.
- `notes` stores optional template notes.
- Standard audit fields apply.

## Rigs (Draft)
- `owner_user_id` or `owner_callsign_id` stores ownership (XOR).
- `rig_type_id` assigns the category; use `other` when needed.
- `rig_model_id` links to a known template (optional).
- `name` is the user-facing label.
- `manufacturer` and `model` store ad-hoc values when no template exists.
- `serial_number` stores optional serial data.
- `notes` stores optional rig notes.
- `is_active` disables a rig without deleting data.
- Standard audit fields apply.

## Bands (Draft)
- `code` is the canonical band key (e.g., `20m`) and is unique per scope.
- `name` is the display label (e.g., "20 meters").
- `adif_code` stores the ADIF band name/code used in imports/exports.
- `lower_freq_hz` and `upper_freq_hz` store band edges in Hz.
- `is_custom` flags user-defined entries not in the reference pack.
- `scope` defines sharing: `global`, `user`, `callsign` (tenant later).
- `owner_user_id` or `owner_callsign_id` links custom entries to their owner.
- `is_active` disables a band without deleting history.
- Standard audit fields apply.
- `code=other` is a global fallback when no predefined band matches.

## Modes (Draft)
- `code` is the canonical mode key (e.g., `SSB`, `FT8`) and is unique per scope.
- `name` is the display label.
- `adif_mode` and `adif_submode` store ADIF mode fields.
- `category` stores high-level grouping (`voice`, `data`, `cw`).
- `is_custom` flags user-defined entries not in the reference pack.
- `scope` defines sharing: `global`, `user`, `callsign` (tenant later).
- `owner_user_id` or `owner_callsign_id` links custom entries to their owner.
- `is_active` disables a mode without deleting history.
- Standard audit fields apply.
- `code=other` is a global fallback when no predefined mode matches.

## Station Rigs (Draft)
- `station_id` and `rig_id` map rigs to stations.
- `is_primary` marks the default rig for a station and type.
- `notes` stores optional mapping notes.
- Enforce unique active mapping on `(station_id, rig_id)`; primary-per-type is enforced in app logic.
- Standard audit fields apply.

## Logbook Entries (Draft)
- `timestamp_utc` stores QSO start time; `end_timestamp_utc` is optional.
- `band_tx_id`/`band_rx_id` and `frequency_tx_hz`/`frequency_rx_hz` store split data.
- `band_tx_id` and `band_rx_id` reference `bands` (internal IDs mapped via stable `public_id`).
- `mode_id` references `modes` (internal ID mapped via stable `public_id`).
- Unknown bands or modes should use `code=other` and record details in notes.
- `other_callsign` is canonical uppercase; `other_callsign_id` is optional when the callsign exists in-system.
- `rst_sent` and `rst_received` are optional.
- `other_operator_name`, `other_qth`, and `other_grid_locator` store optional counterparty metadata.
- `other_dxcc_entity_id`, `other_itu_zone`, and `other_cq_zone` store inferred or imported zones.
- `other_iota_ref`, `other_sota_ref`, `other_pota_ref`, `other_wwff_ref` store optional awards identifiers.
- `exchange_sent` and `exchange_received` store optional exchange strings.
- `qsl_via` stores optional routing hints.
- `contest_placeholder` stores contest identifiers until a dedicated contest model is added.
- `other_lookup_source` records provenance (`manual`, `internal`, `qrz`, `import`).

## Nodes (Draft)
- `public_id` is the stable node identifier used in audit and sync.
- `name` is the display label.
- `node_type` is a text enum (e.g., `local`, `remote`, `cloud`).
- `endpoint_url` stores optional remote endpoint metadata.
- `last_seen_at` records last contact time.
- `is_active` disables a node without deleting data.
- `notes` stores optional node notes.
- Standard audit fields apply.

## Auditability (Draft)
- Core table changes are recorded in `audit_events` (append-only).
- `entity_type` stores the affected table name.
- `entity_public_id` references the target entity for stable lookup.
- `action` values: `create`, `update`, `delete`, `merge`, `restore`.
- `actor_user_id` references the internal user ID (system user for automation).
- `origin_node_id` references the internal node ID for sync/import events.
- `source` records provenance (`manual`, `import`, `sync`, `integration`).
- `event_time` stores the UTC event timestamp.
- `payload_before`/`payload_after` store diffs for updates and full snapshots for create/delete.
- `notes` stores optional audit notes.
- Audit coverage is mandatory in SaaS; MVP uses the same structure for compatibility.

## Types and Compatibility
- Prefer compatible types: `text`, `integer`, `real`, `blob`, `boolean` (SQLite alias).
- Avoid DB-native enums; use text enums with application validation.
- Use dual identifiers for core tables:
  - `internal_id` is the primary key (SQLite `INTEGER PRIMARY KEY`, PostgreSQL `BIGINT` identity).
  - `public_id` is a ULID stored as `TEXT` with a `UNIQUE` index.
  - Foreign keys always reference `internal_id`.
  - Sync/import flows use `public_id` and map to local `internal_id` before writing child rows.

## Indexing Strategy (Initial)
- `logbook_entries`: `(timestamp_utc)`, `(other_callsign)`, `(frequency_tx_hz)`, `(frequency_rx_hz)`, `(band_tx_id)`, `(band_rx_id)`, `(mode_id)`
- `qsl_status`: `(logbook_entry_id, channel, direction)`
- `callsign_memberships`: `(callsign_id)`, `(user_id)`
- `stations`: `(owner_user_id)`, `(owner_callsign_id)`
- `audit_events`: `(entity_public_id)`, `(event_time)`

## Soft Delete Policy
- Use `deleted_at` on user-visible data.
- Never hard-delete log entries in MVP.

## QSL Status and Events Model
- `qsl_events` is append-only history of QSL changes per logbook entry, channel, and direction.
- `qsl_status` stores the latest state per `(logbook_entry_id, channel, direction)`.
- `direction` values: `sent` or `received`.
- `status` values (MVP): `sent`, `received`.
- Pending is represented by the absence of a `qsl_status` row for the given channel/direction.
- `qsl_status` should be unique on `(logbook_entry_id, channel, direction)` for active rows.
- `qsl_events` includes `event_time`, `actor_user_id`, `origin_node_id`, `change_source`, and optional `note`.
- `qsl_status` includes `status_at`, `actor_user_id`, `origin_node_id`, `change_source`, and optional `note`.

## QSL Status (Draft)
- `logbook_entry_id` (FK, int64) links the QSO record.
- `channel` (text) identifies the QSL channel (e.g., `lotw`, `eqsl`, `paper`, `bureau`, `direct`, `internal`).
- `direction` (text) is `sent` or `received`.
- `status` (text) is `sent` or `received` (MVP).
- `status_at` (timestamp UTC) stores when the status was recorded.
- `actor_user_id` (FK, int64) records who set the status.
- `origin_node_id` (FK, int64, nullable) records the source node for sync/import.
- `change_source` (text) records provenance (`manual`, `import`, `sync`, `integration`).
- `note` (text, nullable) stores optional comments.
- Standard audit fields apply.

## QSL Events (Draft)
- `logbook_entry_id` (FK, int64) links the QSO record.
- `channel` (text) identifies the QSL channel (e.g., `lotw`, `eqsl`, `paper`, `bureau`, `direct`, `internal`).
- `direction` (text) is `sent` or `received`.
- `status` (text) is `sent` or `received` (MVP).
- `event_time` (timestamp UTC) stores when the event was recorded.
- `actor_user_id` (FK, int64) records who triggered the event.
- `origin_node_id` (FK, int64, nullable) records the source node for sync/import.
- `change_source` (text) records provenance (`manual`, `import`, `sync`, `integration`).
- `note` (text, nullable) stores optional comments.
- Standard audit fields apply.


## Notes
- Schema will evolve during implementation; update this document as needed.
