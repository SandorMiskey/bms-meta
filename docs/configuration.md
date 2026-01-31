# Configuration Guide

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Overview
- Format: TOML
- File name: `config.toml`
- Scope: server and client configs use the same filename, but different sections.
- Precedence (highest to lowest): server-required overrides > CLI > env > local file > server defaults
- Merge: server provides defaults, local overrides non-critical fields, server-required overrides always win.

## Config Discovery and Parsing
- Config path resolution order: CLI `--config` override (if set) -> `BMS_CONFIG` env var (if set) -> default config path.
- `bmsd` and `bms` accept `--config` to set the override path explicitly.
- Default config path is derived from `os.UserConfigDir()` + `bms/config.toml` (see platform-specific layout below).
- Override paths are used as-provided except for `~` expansion (relative paths resolve against the process working directory).
- `~`, `~/`, and `~\` expand to the user home directory; other env vars and glob patterns are not expanded.
- Path resolution returns a candidate path without touching the filesystem; file existence is checked when loading.
- Missing config files return `ErrConfigNotFound` and do not imply fallback searches.
- If the resolved path points to a directory, loading returns `ErrConfigPathIsDir`.
- The loader does not create directories and does not search alternate locations (no CWD or `/etc` fallback).
- Parsing is strict: unknown keys cause a validation error.
- Server processes `[server]`, `[database]`, `[auth]`, `[logging]`, `[grpc]`, `[rest]`,
  `[websocket]`, `[integrations]`, `[plugins]`, `[sync]`, `[telemetry]` sections.
- Clients process `[client.*]` sections and ignore server-only configuration.

## Merge and Precedence Rules
1. Load defaults (server-provided baseline).
2. Apply local `config.toml` overrides.
3. Apply environment variables.
4. Apply CLI flags.
5. Apply server-required overrides (explicit allowlist of fields).

## Resolution Pipeline (Implementation)
- `ResolveConfig` implements the precedence rules in a fixed order and returns the
  resolved config plus the resolved path of the local config file.
- `ResolveConfigAndValidate` runs `ResolveConfig` and then validates the result,
  returning aggregated field errors without attempting fallback behavior.
- `ResolveConfigDiagnostics` runs `ResolveConfig`, collects warnings, and then
  validates the result so startup code can log both warnings and errors.
- Step 1: `DefaultConfig()` constructs the baseline config with documented defaults.
- Step 2: `LoadConfigOverlayFromDefault(overridePath)` resolves the config path and
  decodes TOML into an overlay (not a full config).
  - Missing files return `ErrConfigNotFound`.
  - Directory paths return `ErrConfigPathIsDir`.
  - There is no fallback to other locations and no implicit "defaults-only" mode.
- Step 3: `ApplyOverlay` merges the file overlay into the base defaults.
  - Only explicitly set keys override; absent keys leave defaults intact.
- Step 4: `ApplyEnvOverrides` merges environment values into the config.
  - Empty env values are ignored to avoid accidental overrides.
- Step 5: `ApplyOverlay` merges CLI overrides (when provided by the CLI layer).
  - The CLI overlay follows the same "nil means no override" semantics as the file overlay.
- Step 6: `ApplyServerOverrides` enforces server-required overrides (auth/sync allowlist).
  - Any non-allowlisted fields in the server override input are ignored.
- Errors from any step are returned immediately without fallback or retries.

## Default Values (Current)
- `auth.token_ttl`: `168h`
- `auth.refresh_before_expiry`: `0.8`
- `auth.token_storage`: `keychain`
- `client.auth.refresh_before_expiry`: `0.8`
- All other fields are zero-valued until overridden by file/env/CLI/server inputs.

## Logging Defaults and Fields
- Logging is configured via `logging.format` and `logging.level` and can be set
  per component by providing different defaults at initialization time.
- Recommended defaults:
  - Server components: `logging.format = json`, `logging.level = info`
  - CLI/TUI components: `logging.format = text`, `logging.level = info`
- `NewLogger` applies the config values when set; otherwise it falls back to the
  component defaults provided by the caller.
- Canonical log fields:
  - `component`, `event`, `request_id`, `trace_id`, `server_id`, `environment`
  - Diagnostics: `config_path`, `warnings_count`, `redacted`
- Component identifiers are standardized (e.g., `config`, `auth`, `database`,
  `grpc`, `rest`, `websocket`, `sync`, `integrations`, `plugins`, `telemetry`).

## Request and Trace Identifiers
- `request_id` and `trace_id` are stored in `context.Context` using logging helpers
  so middleware and handlers can attach identifiers once per request.
- Identifiers are stored as strings for now; typed wrappers may be introduced later
  as tracing is integrated and ID formats are standardized.

## Startup Diagnostics Logging
- Entry points should call `LogConfigDiagnostics` after resolving config to
  emit startup diagnostics without logging directly inside the config package.
- Emitted events:
  - `config_loaded`: includes `config_path`, `warnings_count`, and `redacted=true`.
  - `config_warnings`: emitted only when warnings are present.
- Warning payload format depends on the log format:
  - JSON logs: `warnings` is a list of `{path, message}` objects.
  - Text logs: `warnings` is a single semicolon-delimited string.
- The `config_loaded` event logs the redacted config payload under `config`.

## Health and Readiness Endpoints
- The health server listens on the REST listener address (`rest.address`).
- If `rest.address` is empty, the health server is disabled and a startup
  warning is logged.
- `/healthz` always returns HTTP 200 with `ok` to indicate the process is alive.
- `/readyz` returns HTTP 200 with `ready` once the service is marked ready;
  otherwise it returns HTTP 503 with `not ready`.
- Readiness is set after configuration is successfully resolved and validated.
- When the REST server is introduced, health endpoints will be served by the
  same listener to avoid address conflicts.

## Environment Overrides (Current)
- `BMS_DATABASE_DSN` -> `database.dsn`
- `BMS_DATABASE_DRIVER` -> `database.driver`
- `BMS_SERVER_ID` -> `server.id`
- `BMS_AUTH_MODE` -> `auth.mode`
- `BMS_SYNC_MODE` -> `sync.mode`
- Environment overrides are decoded as strings and cast to enum types where needed;
  semantic validation occurs later during config validation.
- Empty environment values are ignored and do not override the base config.

## CLI Overrides (Planned)
- The CLI layer is expected to construct a `ConfigOverlay` using pointer fields,
  mirroring the file overlay semantics (nil means "no override").
- The CLI overlay is merged after env overrides and before server-required overrides.

## Overlay Model Rationale
- The merge pipeline must distinguish between an unset value and an explicit zero value
  (e.g., `auth.enabled = false` must override defaults, while an absent key must not).
- The runtime `Config` struct is kept non-pointer to avoid pervasive nil checks and to keep
  application code straightforward; that means it cannot represent "unset" directly.
- To preserve unset vs. explicit values, configuration files are decoded into pointer-based
  overlay structs that mirror the config schema; each field is optional and only overrides
  the base when it is non-nil.
- The overlay types intentionally duplicate the config schema to keep decoding strongly
  typed and to allow strict TOML validation (`DisallowUnknownFields`) without reflection.
- The overlay is applied by explicit merge helpers that only copy non-nil fields into the
  base `Config`, keeping override semantics readable and auditable.
- Alternatives were considered and rejected:
  - Making all runtime config fields pointers increases nil handling across the codebase.
  - Using TOML metadata or untyped maps loses type safety and complicates validation.
  - Reflection-based merges reduce readability and make override rules harder to audit.

## Loader Roles (Runtime vs Overlay)
- Two file loaders exist to keep the merge pipeline explicit and type-safe.
- `LoadConfig` reads TOML directly into the runtime `Config` struct.
  - Use it when the config is already fully resolved (for example, server-provided defaults
    or tests that do not require merge semantics).
  - The runtime struct uses non-pointer fields, so it cannot represent an "unset" value.
- `LoadConfigOverlay` reads TOML into pointer-based overlay structs.
  - Use it for local config files, env/CLI overlays, and any partial inputs that must
    preserve "unset" vs. explicit zero values.
  - Each non-nil overlay field overrides the base config during merge.
- The loaders intentionally duplicate the same path validation behavior (missing file,
  directory path) so error semantics remain consistent across both paths.
- This duplication is deliberate for clarity and auditability; a shared helper is an
  acceptable future refactor once the merge pipeline stabilizes.

## Secrets Guidance
- Secrets are allowed in `config.toml` for local use.
- Prefer environment variables or OS keychain when available.
- Token storage uses keychain by default; fallback to encrypted file when keychain is unavailable.
- Never log secrets; redact values in diagnostics.

## Auth Model Notes
- Remote nodes may enable both key-based and password-based login; key-based is the default.
- Passwords are node-local and never synchronized between nodes.
- Local offline login relies on device keys stored in `auth_key_secrets`.
- Private keys are encrypted with the auth password by default; users may opt out explicitly.
- Changing the auth password requires re-encrypting stored private keys.
- Device registration happens via pairing or recovery codes; local trust is local-only.

## Validation Rules (Draft)
- `database.driver` must be `sqlite` or `postgres` and requires a matching `database.dsn`.
- `auth.enabled=true` requires at least one of `auth.key_auth.enabled` or `auth.password_auth.enabled`.
- `auth.mode=remote` requires `auth.remote.endpoint`.
- `auth.local_trust.enabled=true` is allowed only when `server.environment=local` and `auth.mode=local`.
- `auth.key_storage.allow_unencrypted=true` must be an explicit opt-in; log a warning when used.
- `sync.enabled=true` requires `sync.mode`.
- Durations (`auth.token_ttl`) must parse; fractions (`auth.refresh_before_expiry`) must be between 0 and 1.
- Unknown keys fail validation to avoid silent misconfiguration.

## Validation Implementation
- Validation is performed by `ValidateConfig` after the merge pipeline has produced
  a resolved config; use `ResolveConfigAndValidate` to run both steps together.
- `ValidateConfig` appends `FieldError` entries for each failed rule instead of
  short-circuiting, so all issues are reported in a single pass.
- `FieldError` carries a dotted field path (e.g., `auth.remote.endpoint`) and a
  human-readable message; `ValidationErrors` implements `error` by concatenating
  all field errors with semicolon separators.
- Validation runs in a deterministic order (database -> auth -> sync -> auth durations)
  to keep error output stable across runs and easy to compare in logs.
- Validation is pure: it does not touch external systems or runtime services.

## Warnings and Operator Alerts
- Non-fatal issues are collected by `CollectConfigWarnings` and returned as a
  `WarningList` so callers can log or surface them without blocking startup.
- Warnings use the same dotted field paths as validation errors for consistency.
- Current warnings:
  - `auth.key_storage.allow_unencrypted`: warns that local keys are stored
    without encryption and should be explicitly reviewed.
- `ResolveConfigDiagnostics` is the recommended entry point for startup logging,
  because it returns warnings alongside any validation errors.
- Warnings are collected before validation so they are available even when
  validation fails and the config cannot be used.

## Testing Notes
- Minimal unit tests cover strict TOML decoding, overlay merge semantics, and
  aggregated validation errors.
- The unknown-key test asserts that `DecodeConfig` returns `invalid config keys`
  with the full key path (e.g., `server.unknown`).
- The overlay test confirms that explicit zero values (such as `sync.enabled=false`)
  override base config values while leaving unrelated fields unchanged.
- The validation test verifies that multiple rule violations are aggregated into
  `ValidationErrors` and that each expected field path is present.
- Additional config tests cover redaction of secrets, loader error paths
  (`ErrConfigNotFound`, `ErrConfigPathIsDir`), and merge precedence across
  file, env, CLI, and server overrides.
- Logging tests cover request/trace context helpers, warning formatting for JSON
  versus text logs, and invalid format/level/component validation.
- Health tests cover `/healthz` and `/readyz` status responses for ready and
  not-ready states.

## Error Handling and Redaction
- Validation returns a list of field-path errors (e.g., `auth.mode`).
- Unknown keys are rejected during decoding with an explicit `invalid config keys` error.
- Loader errors (`ErrConfigNotFound`, `ErrConfigPathIsDir`) are returned as-is by `ResolveConfig`.
- Secrets (passwords, tokens, DSNs) are redacted in logs and diagnostics.

## Redaction and Summary Logging
- `RedactConfig` produces a sanitized copy of the resolved config for safe logging.
- Redaction preserves the full config shape so summaries remain comprehensive.
- The following fields are currently redacted with a `[redacted]` placeholder:
  - `database.dsn`
  - `auth.remote.endpoint`
  - `client.auth.token`
- Endpoints are redacted defensively because URLs may embed credentials.
- Other fields are logged as-is; if a new field can carry secrets, it must be
  added to the redaction list alongside a documentation update.

## Server Config Schema (Draft)
- `server.id`: instance identifier
- `server.environment`: `local` or `remote`
- `database.driver`: `sqlite` or `postgres`
- `database.dsn`: connection string
- `database.migrations`: migrations path
- `auth.enabled`: true/false
- `auth.mode`: `local` | `remote` | `hybrid`
- `auth.remote.endpoint`: endpoint for delegated auth (required when `auth.mode=remote`)
- `auth.key_auth.enabled`: true/false (key-based login)
- `auth.password_auth.enabled`: true/false (password login)
- `auth.key_storage.encrypted`: true/false (encrypt local private keys)
- `auth.key_storage.allow_unencrypted`: true/false (explicit opt-in)
- `auth.recovery.enabled`: true/false
- `auth.recovery.codes`: integer (how many codes to issue)
- `auth.local_trust.enabled`: true/false (local-only, passwordless)
- `auth.token_ttl`: duration (default `168h`)
- `auth.refresh_before_expiry`: fraction (default `0.8`)
- `auth.token_storage`: `keychain` | `file` | `config`
- `auth.device_pairing.enabled`: true/false
- `auth.device_pairing.require_local`: true/false
- `auth.device_pairing.qr`: true/false
- `logging.level`: `debug` | `info` | `warn` | `error`
- `logging.format`: `json` or `text`
- `grpc.address`: bind address
- `rest.address`: bind address
- `websocket.address`: bind address
- `integrations.qrz.enabled`: true/false
- `integrations.lotw.enabled`: true/false
- `integrations.clublog.enabled`: true/false
- `plugins.enabled`: true/false
- `plugins.path`: plugin directory
- `sync.enabled`: true/false
- `sync.mode`: `local` or `remote`
- `telemetry.enabled`: true/false
- `telemetry.endpoint`: endpoint URL

## Client Config Schema (Draft)
- `client.server.address`: gRPC endpoint
- `client.server.rest`: REST endpoint
- `client.auth.token`: auth token
- `client.auth.refresh_before_expiry`: fraction (default `0.8`)
- `client.auth.store_token`: true/false
- `client.theme.name`: theme name
- `client.keymap.name`: keymap name
- `client.plugins.enabled`: true/false
- `client.plugins.path`: plugin directory
- `client.offline.enabled`: true/false

## Server-Required Overrides (Draft)
- `auth.enabled`
- `auth.mode`
- `sync.enabled`
- `sync.mode`
- Applied last in the pipeline to enforce server-required behavior.
- Non-allowlisted fields provided by the server are ignored.

## Server-Provided Configuration
- Server defaults may be user-specific (feature entitlements, UI capabilities).
- Server-provided config includes a version and timestamp for cache checks.
- Clients merge server defaults with local config, except for server-required overrides.

## Cache and Refresh
- Refresh server-provided config on login, reconnect, and periodic intervals (e.g., every 5–15 minutes).
- If the server is unavailable, continue using the last cached server config until refresh succeeds.
- Compare `server_config.version` and `updated_at` to decide whether a merge is needed.

### Example: Server-Provided Config (User Scoped)
```toml
[server_config]
version = 3
updated_at = "2026-01-17T18:00:00Z"
user_id = "user-123"

[features]
contest = true
integrations = ["qrz", "lotw"]
advanced_ui = false
```

## Filesystem Layout (Unix-like)
- Config: `~/.config/bms/`
- Data: `~/.local/share/bms/`
- Cache: `~/.cache/bms/`

## Filesystem Layout (Windows)
- Config/Data (roaming): `%APPDATA%\bms`
- Local data/cache: `%LOCALAPPDATA%\bms`
- Temp/cache: `%LOCALAPPDATA%\Temp\bms`

## Example: Local-Only Server (TOML)
```toml
[server]
id = "local"
environment = "local"

[database]
driver = "sqlite"
dsn = "file:bms.db"
migrations = "db/migrations"

[auth]
enabled = true
mode = "local"
key_auth = { enabled = true }
password_auth = { enabled = true }
key_storage = { encrypted = true, allow_unencrypted = false }
recovery = { enabled = true, codes = 10 }
local_trust = { enabled = true }
device_pairing = { enabled = true, require_local = true, qr = true }
# token settings
# token_ttl = "168h"
# refresh_before_expiry = 0.8
# token_storage = "keychain"

[logging]
level = "info"
format = "text"

[grpc]
address = "127.0.0.1:9000"

[rest]
address = "127.0.0.1:9001"

[websocket]
address = "127.0.0.1:9002"

[integrations]
qrz = { enabled = false }
lotw = { enabled = false }
clublog = { enabled = false }

[plugins]
enabled = false
path = "plugins"

[sync]
enabled = false
mode = "local"

[telemetry]
enabled = false
```

## Example: Remote Client (TOML)
```toml
[client.server]
address = "grpc.example.net:9000"
rest = "https://api.example.net"

[client.auth]
token = "REPLACE_ME"
refresh_before_expiry = 0.8
store_token = true

[client.theme]
name = "default"

[client.keymap]
name = "default"

[client.plugins]
enabled = true
path = "~/.config/bms/plugins"

[client.offline]
enabled = false
```

## Example: Remote Server (TOML)
```toml
[server]
id = "cloud"
environment = "remote"

[database]
driver = "postgres"
dsn = "postgres://user:pass@localhost:5432/bms"
migrations = "db/migrations"

[auth]
enabled = true
mode = "local" # this server handles auth locally; use "remote" to delegate
key_auth = { enabled = true }
password_auth = { enabled = true }
key_storage = { encrypted = true, allow_unencrypted = false }
recovery = { enabled = true, codes = 10 }
local_trust = { enabled = false }
device_pairing = { enabled = true, require_local = false, qr = true }
# token settings
# token_ttl = "168h"
# refresh_before_expiry = 0.8
# token_storage = "keychain"
```
