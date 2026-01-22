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

## Standard Fields (Shared)
- `internal_id` (int64, PK) is the local primary key.
- `public_id` (ULID text, unique) is the stable identifier for sync and APIs.
- `created_at` (timestamp UTC) records creation time.
- `created_by_user_id` (int64 FK) records the creator.
- `updated_at` (timestamp UTC) records the last update.
- `updated_by_user_id` (int64 FK) records the last updater.
- `deleted_at` (timestamp UTC, nullable) marks soft deletion when applicable.
- Append-only tables may omit `deleted_at` and treat rows as immutable history.

## Migration Strategy
- Tool: `golang-migrate` CLI, invoked via Makefile targets.
- Naming: timestamp-based migration files.
- Each migration should target only features common to SQLite and PostgreSQL.
- Keep `schema_migrations` aligned across both migration sets.
- Migrations should run inside a transaction when supported by the database.
- Every migration must provide a `down` rollback.
- Schema parity between SQLite and PostgreSQL is required; exceptions must be documented.

## Migration Naming (Draft)
- Format: `YYYYMMDDHHMMSS_<slug>.up.sql` and `YYYYMMDDHHMMSS_<slug>.down.sql`.
- `<slug>` is short, descriptive, and `snake_case`.
- Use the same timestamp and slug across `shared`, `sqlite`, and `postgres`.
- Baseline schema and seed are separate migrations (e.g., `*_baseline_schema` vs `*_baseline_seed`).
- `shared` contains canonical SQL with the same `.up.sql`/`.down.sql` filenames used by DB-specific folders.

## SQL Layout
- Schemas: `db/schema/sqlite` and `db/schema/postgres` (generated dumps).
- Migrations: `db/migrations/shared`, `db/migrations/sqlite`, and `db/migrations/postgres`.
- `shared` contains canonical SQL that is copied or adapted into the DB-specific folders.
- Queries: split by DB and domain for readability:
  - `internal/storage/sqlite/read/<domain>`
  - `internal/storage/sqlite/write/<domain>`
  - `internal/storage/postgres/read/<domain>`
  - `internal/storage/postgres/write/<domain>`

## Schema Dumps (Generated)
- Purpose: verify that SQLite and PostgreSQL migrations yield identical schemas.
- Content: DDL-only schema dumps generated from migrations; no data is included.
- Location: `db/schema/sqlite` and `db/schema/postgres`.
- Naming: timestamped filenames that include the last migration applied, e.g.
  `schema_20260121_153000_after_20260121150000_baseline.sql`.
- Source of truth: migrations remain authoritative; schema dumps are review artifacts.
- Workflow: dumps are committed so schema parity can be reviewed in code review.
- Rule: schema dump files are generated only; do not edit by hand.

## Baseline and Seed Strategy (Draft)
- Baseline migrations are split into schema and seed steps.
- Schema migrations create all core and lookup tables plus constraints.
- Seed migrations insert minimal, stable reference data required for MVP usage.
- Baseline seeds should use fixed `public_id` values from the reference data pack.
- Minimal seed scope:
  - `rig_types` (radio, amp, antenna, other).
  - `bands` and `modes` with `code=other` plus a small default set.
- Full reference datasets (bands, modes, DXCC, external registries) are imported from
  a reference data pack outside baseline migrations so they can be updated without
  schema changes.

## Rollback Rules (Draft)
- Every migration must include a `down` file with symmetric rollback logic.
- Destructive changes must add a header comment: `-- IRREVERSIBLE: <reason>`.
- Schema rollbacks should drop objects in reverse dependency order.
- Seed rollbacks must delete only the seeded `public_id` values, not entire tables.
- Rollbacks should run inside a transaction when supported by the database.
- Schema dumps must be regenerated and committed after migration changes.

## Rollback Checklist (Draft)
- `down` file exists and matches the `up` intent.
- Any data loss is marked with `IRREVERSIBLE` and documented in the migration.
- Seed `down` targets only seeded `public_id` values.
- Schema dumps updated for both SQLite and PostgreSQL.

## Rollback Enforcement (Draft)
- Pre-run lint is required before applying migrations.
- The lint step runs in Makefile/CI wrappers and blocks migration execution on failure.
- Planned lint checks:
  - Every `*.up.sql` has a matching `*.down.sql`.
  - Destructive statements require an `-- IRREVERSIBLE:` header.
  - Seed rollbacks delete only seeded `public_id` values.
  - Shared/sqlite/postgres migrations share the same timestamp/slug.
  - Schema dumps are regenerated and committed after changes.
- The migration runner should invoke lint first (e.g., a `make migrate-check` step) and abort on errors.

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
- `auth_credentials`: password-based credentials (node-local).
- `auth_sessions`: session tokens and client metadata.
- `auth_keys`: public keys per device for key-based login.
- `auth_key_secrets`: local encrypted private keys (node-local).
- `auth_recovery_codes`: one-time recovery codes for device registration.
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

## Record Locks (Draft)
- Function: track lock history for logbook entries and enforce exclusive edits.
- `logbook_entry_id` (int64 FK) links the locked QSO.
- `locked_by_user_id` (int64 FK) records who applied the lock.
- `locked_at` (timestamp UTC) stores when the lock was created.
- `reason` (text, nullable) stores the lock reason.
- `unlocked_by_user_id` (int64 FK, nullable) records who removed the lock.
- `unlocked_at` (timestamp UTC, nullable) stores when the lock was removed.
- `unlock_reason` (text, nullable) stores the unlock reason.
- `origin_node_id` (int64 FK, nullable) records the originating node for sync/import.
- Standard fields apply.
- Constraint: one active lock per logbook entry (`unlocked_at IS NULL`).

## Auth Tables (Draft)
- `auth_credentials` stores password hashes for node-local logins and offline fallback.
- `auth_sessions` stores session tokens for local and remote auth flows.
- `auth_keys` stores public keys for device-based login.
- `auth_key_secrets` stores encrypted private keys for offline device auth.
- `auth_recovery_codes` stores one-time recovery codes.

## Auth Storage and Offline Fallback (Draft)
- Passwords are node-local and never synchronized between nodes.
- Remote (SaaS) login supports both key-based and password-based auth; key-based is the default.
- Local nodes may disable password login and rely on device keys only.
- Local offline login uses device keys stored in `auth_key_secrets`.
- `auth_key_secrets` exist only on the local node; remote nodes store public keys only.
- Private keys are encrypted with the auth password by default; users may opt out of encryption explicitly.
- Changing the auth password requires re-encrypting stored private keys.
- Device registration is performed by pairing an existing device or by recovery codes.
- Local trust (passwordless) is allowed only in local-only mode and is enabled by default unless disabled.

## Auth Credentials (Draft)
- Function: store password hashes for local or remote login.
- `user_id` (int64 FK) links the credential to a user.
- `password_hash` (text) stores an Argon2id hash.
- `password_updated_at` (timestamp UTC) records the last password change.
- `failed_attempts` (int) counts consecutive failures for lockout logic.
- `last_failed_at` (timestamp UTC, nullable) records the last failure time.
- `credential_source` (text) is `local` or `remote`.
- Standard fields apply.

## Auth Sessions (Draft)
- Function: store session tokens and client metadata.
- `user_id` (int64 FK) links the session to a user.
- `token_hash` (text) stores a hash of the session token.
- `expires_at` (timestamp UTC) stores token expiry.
- `refreshed_at` (timestamp UTC, nullable) records refresh rotations.
- `revoked_at` (timestamp UTC, nullable) records explicit revocation.
- `last_used_at` (timestamp UTC, nullable) records last use.
- `client_name` (text, nullable) identifies the client (e.g., `bms-cli`).
- `client_version` (text, nullable) stores the client version.
- `ip_address` (text, nullable) records the last known IP.
- `user_agent` (text, nullable) records the client user agent.
- `session_source` (text) is `local`, `remote`, or `delegated`.
- Standard fields apply.

## Auth Keys (Draft)
- Function: store public keys for device-based login.
- `user_id` (int64 FK) links the key to a user.
- `public_key` (text) stores the public key material.
- `key_fingerprint` (text) stores a stable key fingerprint.
- `key_algorithm` (text) stores the algorithm name.
- `device_label` (text, nullable) stores a user-friendly label.
- `created_at` (timestamp UTC) records registration time.
- `last_used_at` (timestamp UTC, nullable) records last use.
- `revoked_at` (timestamp UTC, nullable) records revocation.
- Standard fields apply.

## Auth Key Secrets (Draft)
- Function: store encrypted private keys for offline auth.
- `auth_key_id` (int64 FK) links to the public key.
- `encrypted_private_key` (blob/text) stores the encrypted private key payload.
- `encryption_salt` (blob/text) stores the salt used for key encryption.
- `encryption_kdf` (text) stores KDF settings (e.g., Argon2id params).
- `is_encrypted` (bool) indicates whether encryption is enabled.
- Standard fields apply.

## Auth Recovery Codes (Draft)
- Function: store one-time recovery codes for device registration.
- `user_id` (int64 FK) links to the user.
- `code_hash` (text) stores a hash of the recovery code.
- `issued_at` (timestamp UTC) records creation time.
- `used_at` (timestamp UTC, nullable) records consumption time.
- `revoked_at` (timestamp UTC, nullable) records revocation.
- Standard fields apply.

## Ownership and Membership (Draft)
- `callsign_memberships` binds users to callsigns with a role (`admin`, `write`, `read`).
- `callsign_memberships` includes invite tracking, role source, and optional notes.
- The creator of a callsign is inserted as the first `admin` membership.
- `stations` are owned by either a user or a callsign (not both); enforce via a check constraint.
- `station_callsigns` links stations to allowed callsigns; users can log with a station only if they hold the callsign membership.
- `logbook_entries` reference `callsign_id`, `created_by_user_id`, `operator_user_id`, and `operator_callsign_id`.
- `logbook_entries.station_id` is optional.

## Callsign Memberships (Draft)
- Function: link users to callsigns with roles and invite lifecycle tracking.
- `callsign_id` (int64 FK) links to the callsign.
- `user_id` (int64 FK) links to the user.
- `role` (text) stores `admin`, `write`, or `read`.
- `role_source` (text) records how the role was assigned (e.g., `admin_grant`, `invite_accept`, `system_bootstrap`, `sync_import`).
- `note` (text, nullable) stores optional admin comments.
- `invited_by_user_id` (int64 FK, nullable) links to the inviter.
- `accepted_at` (timestamp UTC, nullable) stores invite acceptance.
- `revoked_at` (timestamp UTC, nullable) stores when access was revoked.
- `revoked_by_user_id` (int64 FK, nullable) records who revoked access.
- `created_at` acts as the invite timestamp; no separate `invited_at` is required.
- Standard fields apply.
- Constraint: unique active membership on `(callsign_id, user_id)` (partial unique).

## Stations (Draft)
- Function: store station profiles, QTH metadata, and zone overrides.
- `name` (text) is unique per owner (user or callsign).
- `registered_qth` (text, nullable) stores the station QTH used for licensing.
- `grid_locator` (text, nullable) stores the station grid square.
- `latitude` and `longitude` (real, nullable) store geolocation.
- `itu_zone` (int, nullable) and `cq_zone` (int, nullable) override callsign defaults.
- `sota_ref`, `pota_ref`, `wwff_ref`, `iota_ref` (text, nullable) store optional awards references.
- `notes` (text, nullable) stores station notes.
- `is_active` (bool) disables a station without deleting data.
- Standard fields apply.

## Station Callsigns (Draft)
- Function: map stations to callsigns allowed to use them.
- `station_id` (int64 FK) links the station.
- `callsign_id` (int64 FK) links the callsign.
- `is_primary` (bool) marks the default station for a callsign.
- Standard fields apply.
- Constraint: unique active mapping on `(station_id, callsign_id)` (partial unique).
- Rule: one primary station per callsign (enforced in application logic).

## Users (Draft)
- Function: store user accounts, defaults, and UI preferences.
- `username` (text, unique) is the login identifier.
- `email` (text, nullable) is used for notifications.
- `display_name` (text, nullable) is the friendly label shown in UIs.
- `default_callsign_id` (int64 FK, nullable) selects the operator callsign used by default.
- `default_station_id` (int64 FK, nullable) selects the station used by default.
- `is_active` (bool) disables a user without deleting data.
- `is_system` (bool) marks reserved system accounts.
- `last_login_at` (timestamp UTC, nullable) tracks the last login time.
- `email_verified_at` (timestamp UTC, nullable) tracks email verification status.
- `timezone` (text, nullable) stores the display timezone.
- `locale` (text, nullable) stores the display locale.
- Standard fields apply.

## Callsigns (Draft)
- Function: store licensed callsigns with default zones and DXCC mapping.
- `callsign` (text, uppercase) is unique for active rows (partial unique with soft delete).
- `registered_qth` (text, nullable) stores the licensed QTH on the callsign.
- `dxcc_entity_id` (int64 FK) references the DXCC entity.
- `itu_zone` (int, nullable) stores the default ITU zone.
- `cq_zone` (int, nullable) stores the default CQ zone.
- `is_active` (bool) disables a callsign without deleting data.
- Standard fields apply.

## Callsign Identifiers (Draft)
- Function: store external membership registries and club identifiers for callsigns.
- `callsign` (text) stores the member callsign in canonical uppercase.
- `identifier_type` (text) stores the brand-style identifier (e.g., `CWops`, `SKCC`, `10-10`).
- `identifier_value` (text) stores the membership value or number.
- `member_name` (text, nullable) stores the member name when available.
- `status` (text, nullable) stores membership status (e.g., `active`, `honorary`).
- `valid_from` and `valid_to` (date, nullable) store membership validity.
- `source_name` (text), `source_version` (text), `source_url` (text, nullable), and `imported_at` (timestamp UTC) store dataset provenance.
- `notes` (text, nullable) stores optional registry notes.
- Standard fields apply.
- The registry is external and not tied to `callsigns` by FK; matches use the callsign text.

## DXCC Entities (Draft)
- Function: define DXCC entities with validity windows for historical accuracy.
- `dxcc_number` (int) stores the official DXCC entity number.
- `name` (text) stores the entity name.
- `continent` (text, nullable) stores the continent code (e.g., `EU`, `NA`).
- `valid_from` (date, nullable) stores the start date of entity validity.
- `valid_to` (date, nullable) stores the end date of entity validity.
- `replaced_by_entity_id` (int64 FK, nullable) links to the successor entity when `valid_to` is set.
- `deleted_at` (timestamp, nullable) marks soft deletion while preserving references.
- Standard fields apply.

## DXCC Prefixes (Draft)
- Function: map callsign prefixes to DXCC entities with validity dates.
- `dxcc_entity_id` (int64 FK) links the prefix to its entity.
- `prefix` (text) stores the callsign prefix (e.g., `HA`, `HG`).
- `valid_from` (date, nullable) stores the start date of prefix validity.
- `valid_to` (date, nullable) stores the end date of prefix validity.
- `is_primary` (bool, nullable) marks a preferred prefix for display.
- Standard fields apply.

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
- Function: define equipment categories for rigs.
- `code` (text) is a stable category key (e.g., `radio`, `amp`, `antenna`, `other`).
- `name` (text) is the display label.
- Standard fields apply.

## Rig Models (Draft)
- Function: store known manufacturer/model templates for rig selection.
- `manufacturer` (text) and `model` (text) identify the template.
- `rig_type_id` (int64 FK, nullable) optionally links the template to a category.
- `notes` (text, nullable) stores optional template notes.
- Standard fields apply.

## Rigs (Draft)
- Function: store user- or callsign-owned equipment inventory.
- `owner_user_id` (int64 FK) or `owner_callsign_id` (int64 FK) stores ownership (XOR).
- `rig_type_id` (int64 FK) assigns the category; use `other` when needed.
- `rig_model_id` (int64 FK, nullable) links to a known template.
- `name` (text) is the user-facing label.
- `manufacturer` (text, nullable) and `model` (text, nullable) store ad-hoc values.
- `serial_number` (text, nullable) stores optional serial data.
- `notes` (text, nullable) stores optional rig notes.
- `is_active` (bool) disables a rig without deleting data.
- Standard fields apply.

## Bands (Draft)
- Function: define band lookup values for log entries and validation.
- `code` (text) is the canonical band key (e.g., `20m`) and is unique per scope.
- `name` (text) is the display label (e.g., "20 meters").
- `adif_code` (text) stores the ADIF band name/code used in imports/exports.
- `lower_freq_hz` and `upper_freq_hz` (int, nullable) store band edges in Hz.
- `is_custom` (bool) flags user-defined entries not in the reference pack.
- `scope` (text) defines sharing: `global`, `user`, `callsign` (tenant later).
- `owner_user_id` (int64 FK, nullable) or `owner_callsign_id` (int64 FK, nullable) links custom entries to their owner.
- `is_active` (bool) disables a band without deleting history.
- Standard fields apply.
- `code=other` is a global fallback when no predefined band matches.

## Modes (Draft)
- Function: define mode lookup values for log entries and validation.
- `code` (text) is the canonical mode key (e.g., `SSB`, `FT8`) and is unique per scope.
- `name` (text) is the display label.
- `adif_mode` (text) and `adif_submode` (text, nullable) store ADIF mode fields.
- `category` (text, nullable) stores high-level grouping (`voice`, `data`, `cw`).
- `is_custom` (bool) flags user-defined entries not in the reference pack.
- `scope` (text) defines sharing: `global`, `user`, `callsign` (tenant later).
- `owner_user_id` (int64 FK, nullable) or `owner_callsign_id` (int64 FK, nullable) links custom entries to their owner.
- `is_active` (bool) disables a mode without deleting history.
- Standard fields apply.
- `code=other` is a global fallback when no predefined mode matches.

## Station Rigs (Draft)
- Function: map rigs to stations and mark defaults.
- `station_id` (int64 FK) links the station.
- `rig_id` (int64 FK) links the rig.
- `is_primary` (bool) marks the default rig for a station and type.
- `notes` (text, nullable) stores optional mapping notes.
- Standard fields apply.
- Constraint: unique active mapping on `(station_id, rig_id)`; primary-per-type is enforced in app logic.

## Logbook Entries (Draft)
- Function: store QSO records with split, exchange, and counterparty metadata.
- `timestamp_utc` (timestamp UTC) stores QSO start time; `end_timestamp_utc` (timestamp UTC, nullable) is optional.
- `band_tx_id`/`band_rx_id` (int64 FK) and `frequency_tx_hz`/`frequency_rx_hz` (int, nullable) store split data.
- `band_tx_id` and `band_rx_id` reference `bands` (internal IDs mapped via stable `public_id`).
- `mode_id` (int64 FK) references `modes` (internal ID mapped via stable `public_id`).
- Unknown bands or modes should use `code=other` and record details in notes.
- `other_callsign` (text) is canonical uppercase; `other_callsign_id` (int64 FK, nullable) is optional when the callsign exists in-system.
- `rst_sent` (text, nullable) and `rst_received` (text, nullable) store RST values.
- `other_operator_name` (text, nullable), `other_qth` (text, nullable), and `other_grid_locator` (text, nullable) store counterparty metadata.
- `other_dxcc_entity_id` (int64 FK, nullable), `other_itu_zone` (int, nullable), and `other_cq_zone` (int, nullable) store inferred or imported zones.
- `other_iota_ref` (text, nullable), `other_sota_ref` (text, nullable), `other_pota_ref` (text, nullable), `other_wwff_ref` (text, nullable) store awards identifiers.
- `exchange_sent` (text, nullable) and `exchange_received` (text, nullable) store exchange strings.
- `qsl_via` (text, nullable) stores routing hints.
- `contest_placeholder` (text, nullable) stores contest identifiers until a dedicated contest model is added.
- `other_lookup_source` (text) records provenance (`manual`, `internal`, `qrz`, `import`).
- Standard fields apply.

## Nodes (Draft)
- Function: identify sync/audit origin nodes and remote endpoints.
- `public_id` (ULID text) is the stable node identifier used in audit and sync.
- `name` (text) is the display label.
- `node_type` (text) is a text enum (e.g., `local`, `remote`, `cloud`).
- `endpoint_url` (text, nullable) stores optional remote endpoint metadata.
- `last_seen_at` (timestamp UTC, nullable) records last contact time.
- `is_active` (bool) disables a node without deleting data.
- `notes` (text, nullable) stores optional node notes.
- Standard fields apply.

## Audit Events (Draft)
- Function: append-only audit trail for core entity changes.
- `entity_type` (text) stores the affected table name.
- `entity_public_id` (ULID text) references the target entity for stable lookup.
- `action` (text) values: `create`, `update`, `delete`, `merge`, `restore`.
- `actor_user_id` (int64 FK) references the internal user ID (system user for automation).
- `origin_node_id` (int64 FK) references the internal node ID for sync/import events.
- `source` (text) records provenance (`manual`, `import`, `sync`, `integration`).
- `event_time` (timestamp UTC) stores the event timestamp.
- `payload_before`/`payload_after` (text/JSON) store diffs or snapshots.
- `notes` (text, nullable) stores optional audit notes.
- Append-only table; no `deleted_at`.
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
- `callsign_identifiers`: `(identifier_type, callsign)`
- `stations`: `(owner_user_id)`, `(owner_callsign_id)`
- `audit_events`: `(entity_public_id)`, `(event_time)`
- `record_locks`: `(logbook_entry_id)`, `(unlocked_at)`

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
- Function: store the latest QSL state per logbook entry, channel, and direction.
- `logbook_entry_id` (int64 FK) links the QSO record.
- `channel` (text) identifies the QSL channel (e.g., `lotw`, `eqsl`, `paper`, `bureau`, `direct`, `internal`).
- `direction` (text) is `sent` or `received`.
- `status` (text) is `sent` or `received` (MVP).
- `status_at` (timestamp UTC) stores when the status was recorded.
- `actor_user_id` (int64 FK) records who set the status.
- `origin_node_id` (int64 FK, nullable) records the source node for sync/import.
- `change_source` (text) records provenance (`manual`, `import`, `sync`, `integration`).
- `note` (text, nullable) stores optional comments.
- Standard fields apply.

## QSL Events (Draft)
- Function: append-only history of QSL changes per channel and direction.
- `logbook_entry_id` (int64 FK) links the QSO record.
- `channel` (text) identifies the QSL channel (e.g., `lotw`, `eqsl`, `paper`, `bureau`, `direct`, `internal`).
- `direction` (text) is `sent` or `received`.
- `status` (text) is `sent` or `received` (MVP).
- `event_time` (timestamp UTC) stores when the event was recorded.
- `actor_user_id` (int64 FK) records who triggered the event.
- `origin_node_id` (int64 FK, nullable) records the source node for sync/import.
- `change_source` (text) records provenance (`manual`, `import`, `sync`, `integration`).
- `note` (text, nullable) stores optional comments.
- Standard fields apply.


## Notes
- Schema will evolve during implementation; update this document as needed.
