# Tech Stack

## Language & Runtime

- **Language**: TypeScript (99%), JavaScript, CSS/HTML
- **Runtime**: Node.js (see .nvmrc; currently 24.18.0)
- **Package Manager**: npm 11.8.0+
- **Desktop Shell**: Electron 42.10.0 (see .npmrc target)
- **Native Builds**: build_from_source=true in .npmrc

## Build Tools (Windows x64)

- **MSVC C++ Compiler**: Visual Studio 2026 Community (v18, cl.exe 19.50.35723)
- **MSVC Toolset**: 14.50.35717
- **Windows SDK**: 10.0.26100.0 / 10.0.28000.0
- **Python**: 3.13.3 (for node-gyp native addon builds)

## Key Dependencies

- **Build System**: Gulp (via npm run gulp, see build/)
- **Monaco Editor**: Integrated (src/vs/editor)
- **Extensions**: Bundled in extensions/ (copilot, markdown, git, etc.)
- **Testing**: Mocha, Playwright, custom test harness

## Project Structure

| Path | Description |
|------|-------------|
| src/ | Main VS Code source (TypeScript) |
| extensions/ | Bundled extensions |
| build/ | Build scripts and Gulp tasks |
| scripts/ | Dev/CI scripts (including build.bat) |
| out/ | Compiled output |
| .build/ | Electron download and build artifacts |
