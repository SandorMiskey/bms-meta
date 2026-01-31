# Licensing Guide

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Overview
BMS uses a dual-licensing model:
- Apache-2.0 for core/open components.
- AGPL-3.0-only OR LicenseRef-Commercial for SaaS-critical components (`bms-cloud` repo).

## Repository Boundaries
- `bms-core`: Apache-2.0 components (server, CLI/TUI, proto, plugin API, SDKs).
- `bms-client`: Apache-2.0 components (web/desktop UI).
- `bms-website`: Apache-2.0 components (public website).
- `bms-cloud`: AGPL-3.0-only OR LicenseRef-Commercial components.

## Repository License Files
- Apache-licensed repositories must include `LICENSE` (Apache-2.0 text) and `NOTICE`.
- Dual-licensed components remain isolated in `bms-cloud` with their own licensing files.

## SPDX Templates
- Apache-2.0: `SPDX_Apache.txt`
- AGPL-3.0-only OR LicenseRef-Commercial: `SPDX_AGPL.txt`
- Commercial placeholder: `LICENSE.md`

## Header Placement Rules
- Go, JS/TS, Lua, SQL, Proto, and config files must include SPDX headers.
- Generated code should preserve SPDX headers.
- Do not place Apache headers on AGPL/Commercial components.

## Commercial Builds
- Commercial builds should reference `LicenseRef-Commercial` from `LICENSE.md`.
- Commercial terms will be published separately.

## Change Control
- Update `LICENSING_MATRIX.md` and `ROADMAP.md` when license boundaries change.
