# AGENTS Guidelines

## Scope
- Applies to this repository root.
- This repo currently contains planning docs only; update commands when code arrives.

## Repository Status
- Current files: `MANIFEST.md`, `ROADMAP.md`, `LICENSING_MATRIX.md`, `.DS_Store` (ignore).
- Root-level docs are symlinks pointing to `bms-meta/`.
- No build system or code yet; instructions below anticipate the planned stack.

## Build, Lint, Test (Go)
- Build all: `make build` (preferred) or `go build ./...`.
- Run all tests: `make test` (preferred) or `go test ./...`.
- Run a single package: `go test ./path/to/pkg`.
- Run a single test: `go test ./path/to/pkg -run TestName`.
- Run with verbose output: `go test ./path/to/pkg -run TestName -v`.
- Run integration tests: `go test ./... -run Integration` (if tagged).
- Lint: `make lint` (preferred) or `golangci-lint run ./...` (once configured).
- Format: `make fmt` (preferred) or `gofmt -w` on changed Go files.
- Vet: `make vet` (preferred) or `go vet ./...`.
- Migration deps check: `make dep`.
- Migration lint: `make migrate-check`.
- Migrate up/down: `make migrate-up-sqlite`, `make migrate-down-sqlite`, `make migrate-up-postgres`, `make migrate-down-postgres`.
- Schema dumps: `make migrate-dump-sqlite`, `make migrate-dump-postgres`.

## Build, Lint, Test (Web/Desktop)
- Install deps: `npm install` or `pnpm install` (when `package.json` exists).
- Dev server: `npm run dev`.
- Build: `npm run build`.
- Lint: `npm run lint`.
- Unit tests: `npm test`.
- Run a single test: `npm test -- -t "test name"`.
- Playwright/e2e (if added): `npm run test:e2e`.

## Build, Lint, Test (Docs/CI)
- Markdown lint (if added): `npm run lint:docs` or `markdownlint`.
- Spellcheck (if added): `npm run lint:spelling`.
- CI entrypoint (if configured): `./scripts/ci.sh`.
- CI is deferred; manual builds use Makefiles initially.

## Code Style: General
- Prefer small, cohesive packages with clear ownership.
- Keep functions short; favor explicit over clever.
- Avoid TODOs without a tracking issue or owner.
- Keep public APIs documented with Go doc comments.
- Keep generated code in `gen/` or `pkg/generated/`.
- Prefer tabs over two spaces for indentation where possible (e.g. Makefiles).
- Use Vim-style folding markers where possible: `// Block Name {{{` ... `// Block Name }}}`.
- Prefer the Go standard library; external dependencies require clear justification.
- For `.gitignore`, use SPDX header + blank line, block headers with `{{{`/`}}}`, and a blank line after each block header and before each block end.

## Architecture Principles
- Make MVP foundations forward-compatible so later phases are additive, not core refactors.
- Favor scalable storage decisions that support high-volume logbook data from the start.

## Documentation Standards
- Use detailed, explanatory documentation that clearly distinguishes tables, fields, types, and purpose.
- Record decisions and rationale with enough context to avoid ambiguity later.

## Code Style: Go
- Follow standard Go formatting with `gofmt`.
- Import order: standard library, blank line, third-party, blank line, local modules.
- Avoid one-letter names except short-lived loop indexes.
- Prefer `context.Context` as first arg in public functions.
- Errors: wrap with `%w` and add context; avoid string comparisons.
- Return `error` last; avoid panics except in `main`.
- Prefer `time.Time` over strings for timestamps.
- Use `sqlc` types; avoid raw SQL strings in services.
- Keep interfaces small; depend on abstractions in `internal/`.
- For config, use explicit structs; avoid `map[string]interface{}`.

## Code Style: gRPC/REST
- gRPC: use proto3, explicit field numbers, and clear naming.
- Keep request/response messages small and composable.
- Version APIs by package name or URL prefix.
- REST gateway should mirror gRPC resource names.
- WebSocket events should be versioned and documented.

## Code Style: SQL/Migrations
- One migration per change; keep reversible where possible.
- Use deterministic ordering for migrations (timestamp or increment).
- Prefer indexes for common logbook queries (call, band, time).
- Avoid vendor-specific SQL in shared schemas when possible.
- Require SQLite/PostgreSQL schema parity; use lowest-common-denominator SQL.
- Prefer transactional migrations when supported; always provide down migrations.

## Code Style: TUI/CLI (BubbleTea)
- Keep model updates pure; side effects via commands.
- Separate rendering from state updates.
- Keybindings documented and centralized.
- Themes stored as structured config, not ad-hoc constants.

## Code Style: Web/Desktop
- Prefer simple JS/TS framework aligned with htmx.
- Keep UI state minimal; rely on server-rendered HTML when possible.
- Use CSS variables for themes and reuse palettes.
- Keybindings must mirror TUI where possible.
- Keep desktop wrapper thin; all logic in shared UI package.

## Code Style: Lua Plugins
- Keep plugin API stable; document hooks and data contracts.
- Sandbox plugins; avoid file/network access by default.
- Provide versioned APIs and compatibility notes.

## Error Handling and Logging
- Use structured logging with consistent fields.
- Log at boundaries (RPC, storage, integrations).
- Avoid logging secrets or auth tokens.
- Convert internal errors to user-friendly messages at UI layers.

## Config and Secrets
- Support server and local client configs with clear precedence.
- Store secrets in env vars or OS keychain when available.
- Use XDG base directories on Unix-like systems (`~/.config`, `~/.local/share`, `~/.cache`).
- Provide sample config files with safe defaults.

## Licensing Rules
- All new files must include SPDX headers or license banners.
- Apache-2.0 for CLI/TUI/Web/SDK/proto/plugin API/base server.
- AGPL-3.0-only OR LicenseRef-Commercial for SaaS-critical components (`bms-cloud`).
- Keep dual-licensed code isolated in dedicated directories.
- Record license owner: Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO).

## Repo Structure (Planned)
- `cmd/bmsd` server entrypoint.
- `cmd/bms` TUI/CLI entrypoint.
- `internal/` service logic (auth, logbook, contest, integrations, sync).
- `pkg/` shared SDK/client packages.
- `proto/` gRPC contracts.
- `db/` schemas, migrations, seeds.
- `plugins/` Lua runtime assets.
- `configs/` default configs.
- `deploy/` container definitions.
- `docs/` English documentation.

## Testing Guidance
- Unit tests near implementation (`*_test.go`).
- Table-driven tests for parsing and validation.
- Favor deterministic tests; avoid `time.Now` without injection.
- Add integration tests for DB migrations and gRPC flows.

## Commit/PR Guidance
- Keep commits scoped and descriptive.
- Note license classification in PR descriptions for new components.
- Update `ROADMAP.md` when scope changes.
- Ideas can also originate from `IDEA-BACKLOG.md` and should be triaged into the roadmap.

## Cursor/Copilot Rules
- No `.cursor/rules`, `.cursorrules`, or `.github/copilot-instructions.md` found.

## When Missing Commands
- If build/test tooling is absent, document the new command in this file.
- Prefer a single source of truth in `AGENTS.md` for agent guidance.

## Security and Privacy
- Enforce TLS for remote connections when enabled.
- Authentication optional, but secure defaults.
- Rate-limit external integrations.
- Validate all user input from UI and APIs.
- Redact personal data in logs.
- Use least-privilege DB users when supported.

## Performance
- Use pagination for logbook lists.
- Add indexes for call/date/band queries.
- Cache lookups for QRZ/LoTW.

## UX Notes
- Keep keymaps consistent across TUI/web/desktop.
- Provide clear offline/online status indicators.

## Contact
- Primary owner: Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO).
