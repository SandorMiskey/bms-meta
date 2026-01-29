# Configuration Guide

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Overview
- Format: TOML
- File name: `config.toml`
- Scope: server and client configs use the same filename, but different sections.
- Precedence: CLI > env > local file > server defaults
- Merge: server provides defaults, local overrides non-critical fields, server-required overrides always win.

## Config Discovery and Parsing
- Config path resolution order: CLI `--config` override (if set) -> `BMS_CONFIG` env var (if set) -> default config path.
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

## Error Handling and Redaction
- Validation returns a list of field-path errors (e.g., `auth.mode`).
- Secrets (passwords, tokens, DSNs) are redacted in logs and diagnostics.

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
