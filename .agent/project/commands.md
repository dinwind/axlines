# Project Commands

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
