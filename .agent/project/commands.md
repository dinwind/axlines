# Project Commands

## Scripts Inventory

All project scripts live in `scripts/` (repo root). Build orchestration is
`scripts\build.bat`; everything else is a focused helper.

| Script | Purpose |
|--------|---------|
| `build.bat` | Build orchestrator (install / compile / rebuild / run / watch / clean / sync-axline) |
| `sync-axline-vsix.ps1` | Fetch latest Axline `.vsix` from AuthNexus and replace local copy (see "Axline Extension Sync" below) |
| `code.bat` | Launch VS Code in dev mode (thin wrapper) |
| `code-cli.bat` / `code-cli.sh` | CLI dev launcher (`code-server.js` variants) |
| `code-server.bat` / `code-server.sh` | Run server/remote dev |
| `code-web.bat` / `code-web.sh` | Run web target |
| `node-electron.bat` / `node-electron.sh` | Run Electron with custom Node |
| `sync-agent-host-protocol.ts` | Sync the agent-host protocol |
| `xterm-update.js` / `xterm-update.ps1` | Update the bundled xterm.js |
| `post-merge-cleanup.ps1` / `.sh` | Post-merge branch cleanup (`co branch cleanup`) |
| `start-task-branch.ps1` / `.sh` | Start a task branch |
| `generate-icon.py` | Generate app icons |
| `test.bat` / `test.sh` | Run the test suite |
| `test-documentation.bat` / `.sh` | Documentation checks |
| `test-integration.bat` / `.sh` | Integration tests |
| `test-remote-integration.bat` / `.sh` | Remote integration tests |
| `test-web-integration.bat` / `.sh` | Web integration tests |
| `test-agent-host-e2e.ts` / `-child.ps1` | Agent-host e2e tests |
| `axline.vsix` | **Not a script** — the embedded Axline extension artifact (managed by `sync-axline-vsix.ps1`) |

## Build Script (Windows)

```powershell
# Full build (install deps + compile)
.\scripts\build.bat

# Clean + full rebuild
.\scripts\build.bat rebuild

# Install dependencies only
.\scripts\build.bat install

# Compile only (deps must exist)
.\scripts\build.bat compile

# Build and launch VS Code in dev mode
.\scripts\build.bat run

# Start watch mode for development
.\scripts\build.bat watch

# Clean all build artifacts
.\scripts\build.bat clean

# Sync embedded Axline extension from AuthNexus (embed-for-release)
.\scripts\build.bat sync-axline
```

## npm Scripts Reference

| Command | Description |
|---------|-------------|
| npm run compile | Full compile (client + copilot) |
| npm run watch | Watch mode (transpile + extensions) |
| npm run compile-client | Compile VS Code core (gulp) |
| npm run compile-extensions | Compile built-in extensions |
| npm run typecheck-client | TypeScript type checking |
| npm run test-node | Run Node.js unit tests |
| npm run test-browser | Run browser unit tests |

## Dev Mode Launch

```powershell
.\scripts\build.bat run
# or directly:
.\scripts\code.bat
```

Dev env vars: VSCODE_DEV=1, NODE_ENV=development, VSCODE_CLI=1

## Axline Extension Sync (embed-for-release)

The Axline extension is shipped as a **built-in extension**, embedded via a
local `.vsix` referenced in `product.json` (`builtInExtensions` → `axline.axline`,
with a `vsix` field). Before compiling/packaging, sync the `.vsix` from the
AuthNexus share link so the embedded extension is the latest published version.

```powershell
# One-off manual sync (also updates product.json version + sha256):
.\scripts\build.bat sync-axline

# Or run the worker script directly:
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\sync-axline-vsix.ps1

# Worker options:
#   -Token <token>   AuthNexus share token (defaults to the pinned token)
#   -VsixPath <path> Target .vsix path (defaults to scripts\axline.vsix)
#   -UpdateProductJson  Also patch product.json axline.axline version/sha256
#   -Force              Re-download even if the local file is already current
```

### How it works

1. `GET https://auth.mtsilicon.com/api/public/releases/share/{token}` returns
   JSON metadata (`version`, `fileHash`, `fileSize`, `fileDisplayName`). **No
   login required** — the share token is itself the unauthenticated access grant.
2. Compare the local `.vsix` SHA256 against the published `fileHash`.
3. If different (or `-Force`), download to a `.tmp` file, **verify SHA256** against
   `fileHash`, then atomic-replace `scripts\axline.vsix`. A mismatched download is
   discarded and the old file is left untouched.
4. With `-UpdateProductJson`, the `axline.axline` entry's `version`/`sha256` in
   `product.json` are patched via targeted string replacement (no full-file JSON
   round-trip, so formatting/key-order is preserved).

### Wiring in the build

`build.bat` runs `call :sync_axline` (which invokes the worker with
`-UpdateProductJson`) automatically at the start of `:compile`, `:install`, and
`:run`. On sync failure the build aborts (`exit /b 1`) so an outdated extension
is never packaged. `rebuild`/`full_build` are covered transitively via
`install` + `compile`.

## Product configuration

- `product.json` — product metadata + `builtInExtensions[]` (embed the Axline `.vsix`)
- `.npmrc` — Electron target and `build_from_source` flag
