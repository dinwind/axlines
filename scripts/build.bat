@echo off
setlocal EnableDelayedExpansion

REM ============================================================================
REM AxLine VS Code Build Script - Windows x64
REM Prerequisites: Node.js 24.18.0+, VS 2026/2022 C++ tools, Python 3.x
REM Usage: scripts\build.bat [install|compile|rebuild|run|watch|clean]
REM ============================================================================

set "PROJECT_ROOT=%~dp0.."
cd /d "%PROJECT_ROOT%"

REM --- Locate Visual Studio vcvars64.bat ---
set "VCVARS="
for %%e in (
    "C:\Program Files (x86)\Microsoft Visual Studio\18\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
    "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
    "C:\Program Files\Microsoft Visual Studio\2022\Community\VC\Auxiliary\Build\vcvars64.bat"
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
) do (
    if exist %%e set "VCVARS=%%e" && goto :vcvars_found
)
echo [ERROR] Visual Studio or Build Tools not found.
exit /b 1

:vcvars_found
set "VCVARS=!VCVARS:"=!"
echo [INFO] VS: !VCVARS!
call "!VCVARS!" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] vcvars64.bat failed.
    exit /b 1
)
echo [INFO] MSVC 64-bit toolchain loaded.

REM Derive VS install root for preinstall.ts C++ detection
for %%p in ("!VCVARS!") do set "VS_ROOT=%%~dpp..\..\..\.."
for %%p in ("!VS_ROOT!") do set "VS_ROOT=%%~fp"
set "vs2022_install=!VS_ROOT!"
echo [INFO] vs2022_install=!vs2022_install!

where node.exe >nul 2>&1 || (echo [ERROR] Node.js not found & exit /b 1)
for /f "tokens=*" %%v in ('node -v') do echo [INFO] Node: %%v

REM --- Dispatch ---
if /i "%~1"==""        goto :full_build
if /i "%~1"=="rebuild" goto :rebuild
if /i "%~1"=="install" goto :install
if /i "%~1"=="compile" goto :compile
if /i "%~1"=="run"     goto :run
if /i "%~1"=="watch"   goto :watch
if /i "%~1"=="clean"   goto :clean
if /i "%~1"=="-h"      goto :help
if /i "%~1"=="--help"  goto :help
echo [ERROR] Unknown: %~1
:help
echo Usage: scripts\build.bat [install^|compile^|rebuild^|run^|watch^|clean]
exit /b 0

REM =====================================================================
:clean
echo [CLEAN] Removing build artifacts...
if exist node_modules (rmdir /s /q node_modules 2>nul & echo   node_modules)
if exist .build (rmdir /s /q .build 2>nul & echo   .build)
if exist out (rmdir /s /q out 2>nul & echo   out)
if exist out-build (rmdir /s /q out-build 2>nul & echo   out-build)
echo [CLEAN] Done.
goto :eof

REM =====================================================================
:install
echo [INSTALL] Installing npm deps (10-30 min)...
call npm install
if errorlevel 1 (
    echo [ERROR] npm install failed.
    exit /b 1
)
echo [INSTALL] Done.
goto :eof

REM =====================================================================
:compile
echo [COMPILE] Building VS Code...
if not exist node_modules (echo [ERROR] Run install first & exit /b 1)
call npm run gulp compile -- --no-typecheck
if errorlevel 1 (
    echo [ERROR] Compile failed.
    exit /b 1
)
echo [COMPILE] Done.
goto :eof

REM =====================================================================
:full_build
echo [BUILD] Full build...
if not exist node_modules goto :do_install
if not exist out goto :do_compile
echo [BUILD] Existing build - use rebuild for clean build.
goto :do_compile
:do_install
call :install || exit /b 1
:do_compile
call :compile || exit /b 1
echo [BUILD] Success. Run: scripts\build.bat run
goto :eof

REM =====================================================================
:rebuild
echo [REBUILD] Clean + full build...
call :clean
echo.
call :full_build
goto :eof

REM =====================================================================
:run
echo [RUN] Build ^& launch VS Code...
if not exist node_modules (call :install || exit /b 1)
if not exist out (call :compile || exit /b 1)
echo [RUN] Pre-launch setup...
node build\lib\preLaunch.ts
if errorlevel 1 (
    echo [ERROR] preLaunch failed.
    exit /b 1
)
for /f "tokens=2 delims=:," %%a in ('findstr /R /C:"\"nameShort\".*" product.json') do set "EXE=%%~a.exe"
set "EXE=!EXE: "=!"
set "EXE=!EXE:"=!"
set "CODE=.build\electron\!EXE!"
if not exist "!CODE!" (
    echo [ERROR] Electron not found: !CODE!
    exit /b 1
)
set NODE_ENV=development
set VSCODE_DEV=1
set VSCODE_CLI=1
start "" "!CODE!" . --disable-extension=vscode.vscode-api-tests
echo [RUN] VS Code launched.
goto :eof

REM =====================================================================
:watch
echo [WATCH] Starting dev watch mode...
if not exist node_modules (call :install || exit /b 1)
npm run watch
goto :eof