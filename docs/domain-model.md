# Domain Model (Draft)

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Overview
- This is a living document and will evolve during implementation.
- Two operating modes: contest and normal.
- Timestamps are stored in UTC; user profile stores the preferred timezone.
- Log entry fields will expand over time; treat this as the minimum viable model.

## Core Entities
### User Profile
- `user_id`: unique identifier
- `display_name`
- `default_callsign`
- `timezone`
- `qth`
- `qra_locator`
- `callsigns`: many-to-many via `operator_callsign`

### Operator
- `operator_id`
- `name`
- `qth`
- `qra_locator`

### Callsign
- `callsign_id`
- `callsign`
- `country`
- `prefix`

### CallsignMembership
- `callsign_membership_id`
- `user_id`
- `callsign_id`
- `role` (`admin` | `write` | `read`)
- `created_by`
- `created_at`

### OperatingContext
- `operating_context_id`
- `station_id`
- `operator_id`
- `callsign_id`
- `active_from`, `active_to`

### Station
- `station_id`
- `name`
- `location_name`
- `qth`
- `qra_locator`

### Rig
- `rig_id`
- `manufacturer`
- `model`
- `serial_number`

### RigProfile
- `rig_profile_id`
- `rig_id`
- `protocol` (e.g. flrig, cat)
- `host`
- `port`
- `baud_rate`
- `capabilities`

### StationRig
- `station_id`
- `rig_profile_id`
- `active_from`, `active_to`

### Contest
- `contest_id`
- `name`
- `ruleset_id`
- `start_time`, `end_time`

### ContestRuleset
- `ruleset_id`
- `name`
- `exchange_schema` (key list + validation rules)
- `multiplier_scheme`

### ExchangeItem
- `exchange_item_id`
- `log_entry_id`
- `direction` (sent | recv)
- `field_key`
- `field_value`
- `ordinal`

### CallsignHistory (derived cache)
- `callsign_id`
- `first_seen`, `last_seen`
- `qso_count`
- `last_exchange`
- `last_band`, `last_mode`
- `source`

### CallsignProfile (derived cache)
- `callsign_id`
- `operator_name`
- `qth`
- `qra_locator`
- `external_ids`
- `updated_at`
- `source`

### AwardProgress (future)
- `award_id`
- `callsign_id`
- `progress_state`
- `last_updated`

## Access Control Notes
- Callsign membership is many-to-many between users and callsigns.
- The callsign creator is the first `admin`.
- `admin` can grant/revoke roles and unlock any record.
- `read` can view only.
- `write` can edit and add QSOs; may edit own contacts unless locked.
- Record locks apply at the log-entry level.
- Locked records are immutable for `write` role unless an admin unlocks them.
- Optional: allow `write` to lock own records when permitted by admin policy.

## Log Entry Shapes
### Contest Mode (minimal + variable exchange)
Base fields:
- `log_entry_id`
- `operating_context_id`
- `contest_id`
- `timestamp_utc`
- `frequency_hz`
- `mode_enum`
- `mode_custom` (free-form override when mode is not in enum)
- `other_callsign`

Variable fields:
- `exchange_items` (key/value pairs validated by contest ruleset)

### Normal Mode (fixed)
- `log_entry_id`
- `operating_context_id`
- `timestamp_utc`
- `frequency_hz`
- `band` (derived from frequency mapping)
- `mode_enum`
- `mode_custom` (free-form override when mode is not in enum)
- `other_callsign`
- `rst_sent`
- `rst_recv`
- `other_operator_name`
- `other_qth`
- `note`

QSL status and events:
- `qsl_status` stores the latest state per source.
- `qsl_events` stores the full audit trail per source.
- `qsl_status.source`: `internal`, `paper`, `lotw`, `clublog`, `qrz`
- `qsl_status.status`: `unsent`, `sent`, `received`
- `qsl_status.sent_at`
- `qsl_status.received_at`
- `qsl_status.note`
- Sent and received are independent; a QSL may be received before sent.
- UI status should be derived from `sent_at` and `received_at`.
- `qsl_events.status`: `sent`, `received`, `confirmed`
- `qsl_events.event_time`
- `qsl_events.note`

Internal QSL rules:
- If both callsigns exist in the system and a QSO is logged, generate an `internal` QSL event.
- Match by timestamp, band, mode, and callsign pair.
- Initial internal event defaults to `received`.

## Relationships
- A user can operate multiple callsigns.
- A callsign can be used by multiple operators.
- `OperatingContext` connects operator, callsign, and station.
- `LogEntry` references `OperatingContext` and optionally `Contest`.
- Contest exchange fields are defined by `ContestRuleset` and stored in `ExchangeItem`.

## Band and Mode Handling
- Store `frequency_hz` on each log entry.
- Use a band mapping table to derive band from frequency.
- `mode_enum` is a known set (CW, SSB, RTTY, SSTV, FT8, FT4, etc.).
- `mode_custom` allows free-form mode labels when not covered by enum.

## Notes
- Callsign history and profile caches can be regenerated from log data.
- The field set will expand in later phases (contest metadata, awards, integrations).
