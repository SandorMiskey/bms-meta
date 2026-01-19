# BMS manifest

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Concept

- modern, client-server amateur radio logging program
- for everyday and contest use
- UI: TUI, CLI, web (remote or local, in a browser), desktop (Tauri/Electron desktop app)
- priorities:
    - primary priority: server and TUI/CLI
    - second priority: web and desktop app
    - least important: mobile app
- LoTW, QRZ.com, and Clublog integration (Clublog in a later phase)
- server components (microservices) can synchronize to remote instances
    - BMS Cloud (like QRZ or Clublog, plus off-site backups, later phase)
    - M/S or M/M operation in contest environments
    - multi-site or multi-computer operation with backups
- radio CAT support via FLrig or natively
- fully open source
- documentation in English
- simple installation package: client (desktop or TUI) with bundled server, all local
- advanced installation: freely install and configure components separately

## Tech stack

### Server

- authentication (with an option to disable), one server <> multiple clients, concurrent use
- gRPC for server-to-server synchronization
- gRPC for TUI-to-server communication
- websocket for browser and Tauri/Electron clients
- REST API for integrations
- Go implementation
- sqlc
- SQLite/Turso and PostgreSQL support
- microservice containers
- htmx support
- Lua-based plugins, e.g. UDCs (contest rules) and award/statistics tracking implementations
- macOS, Linux, *BSD, Windows
- import/export ADIF and other log formats

### TUI/CLI

- Go implementation
- BubbleTea
- connect to local or remote instances
- themes (preferably Neovim-style themes)
- key bindings modeled after Neovim
- Neovim-like client configuration options: Lua config, plugins
- configuration can come from the server component and can also be local

### Web UI

- simplest JS/TS framework
- CSS, themes
- connect to local or remote instances
- htmx
- themes (preferably Neovim-style themes)
- key bindings modeled after Neovim
- Neovim-like client configuration options: (Lua if possible) config, plugins

### Desktop application

- Web UI, but in a Tauri/Electron environment
- connect to local or remote instances
- themes (preferably Neovim-style themes)
- key bindings modeled after Neovim
- Neovim-like client configuration options: (Lua if possible) config, plugins
- configuration can come from the server component and can also be local

### Mobile

- last, lowest priority
- connect to a remote server or BMS Cloud account
- iOS and Android
- technology will be determined later

## Functionality

### Contest

- cluster support:
    - DX cluster library
    - ability to switch
    - communication monitoring
    - display new spots and indicate when we are spotted
    - RBN support
- bandmap
- callsign validation (N, N+1)
- score calculation and prediction
- propagation data
- multiplier support
- SO2V, SO2R, 2BSIQ support
- one server for multiple clients
- CW support
- metadata support: callsign metadata, history, expected exchange, club memberships
- RTC and contestonlinescore.com support
- statistics, AI tools

### Everyday use

- QRZ.com data display
- LoTW and Clublog integration
- awards (DXCC, WAS, WAZ), statistics
- CW support
- metadata support: callsign metadata, history
- propagation data
- DXpeditions data

## Future plans:

- digital modes (FTx) support
- remote operation support: keyer, UltraBeam, Station Master, etc.
- Winlink, APRS, LoRa support
- KYC (for awards, like LoTW), private permissioned or public blockchain support
- POTA/SOTA/IOTA support (also in the mobile app)
- BMS Cloud
    - social network
    - QRZ.com-like services
    - local client, server in the cloud
- contest evaluation plugin (UBN)

# License structure

## Apache 2.0
- CLI / TUI
- Web UI
- SDK / API clients
- Protocol definitions
- Plugin API
- Base self-hosted server (single-user / single-station)

## Dual-licensed (AGPL or Commercial)
SaaS-critical server components:
- multi-tenant user management
- cloud sync
- cluster / spot / realtime feed
- contest coordination
- AI / statistics
- historical big-data
