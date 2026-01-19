# BMS Component-to-License Matrix

## License Notice
Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)

This document is licensed under Apache-2.0.

## Purpose
- Define which components are Apache-2.0 vs AGPL-3.0-only OR LicenseRef-Commercial.
- Clarify repository boundaries for dual-licensed components.
- Repo names are placeholders until the final product name is locked.

## Matrix
| Component Area | Repository | License | Notes |
| --- | --- | --- | --- |
| CLI/TUI | `bms-core` | Apache-2.0 | CLI + TUI apps and shared terminal UX. |
| Web UI | `bms-client` | Apache-2.0 | Browser UI package. |
| Desktop wrapper | `bms-client` | Apache-2.0 | Tauri/Electron wrapper around Web UI. |
| SDK/API clients | `bms-core`, `bms-client` | Apache-2.0 | Go/TS client libraries. |
| Protocol definitions | `bms-core` | Apache-2.0 | gRPC/proto contracts. |
| Plugin API | `bms-core` | Apache-2.0 | Lua plugin interfaces and host API. |
| Base self-hosted server | `bms-core` | Apache-2.0 | Single-user/single-station runtime. |
| Website | `bms-website` | Apache-2.0 | Public docs/landing site. |
| Multi-tenant user management | `bms-cloud` | AGPL-3.0-only OR LicenseRef-Commercial | Tenant isolation and identity. |
| Cloud sync | `bms-cloud` | AGPL-3.0-only OR LicenseRef-Commercial | Hosted sync pipelines and replication. |
| Cluster/spot/realtime feeds | `bms-cloud` | AGPL-3.0-only OR LicenseRef-Commercial | Aggregated realtime feeds. |
| Contest coordination services | `bms-cloud` | AGPL-3.0-only OR LicenseRef-Commercial | Team/multi-site contest ops. |
| AI/statistics services | `bms-cloud` | AGPL-3.0-only OR LicenseRef-Commercial | Analytics and ML-driven insights. |
| Historical big-data | `bms-cloud` | AGPL-3.0-only OR LicenseRef-Commercial | Long-term archive and pipelines. |
| BMS Cloud services | `bms-cloud` | AGPL-3.0-only OR LicenseRef-Commercial | SaaS product surface. |

## Boundary Rules
- AGPL/Commercial components live in the `bms-cloud` repository with no code sharing that would blur license lines.
- Shared interfaces must live in Apache-2.0 repos (or re-implemented) to avoid license mixing.
- Commercial builds should reference `LicenseRef-Commercial` from `LICENSE.md`.
- Any component reclassification requires updating this matrix and `ROADMAP.md`.
