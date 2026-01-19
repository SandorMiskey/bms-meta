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

## Server Config Schema (Draft)
- `server.id`: instance identifier
- `server.environment`: `local` or `remote`
- `database.driver`: `sqlite` or `postgres`
- `database.dsn`: connection string
- `database.migrations`: migrations path
- `auth.enabled`: true/false
- `auth.mode`: `local` or `remote`
- `auth.token_ttl`: duration (default `168h`)
- `auth.refresh_before_expiry`: fraction (default `0.8`)
- `auth.token_storage`: `keychain` | `file` | `config`
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

## Client Config Schema (Draft)
- `client.server.address`: gRPC endpoint
- `client.server.rest`: REST endpoint
- `client.auth.token`: auth token
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
enabled = false
mode = "local"
token_ttl = "168h"
refresh_before_expiry = 0.8
token_storage = "keychain"

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
