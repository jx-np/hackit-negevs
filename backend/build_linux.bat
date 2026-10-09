@echo off
REM Cross-compile the Community Scam Shield API server for Linux amd64 (from Windows).
REM Output: builds\hackit-16-backend-linux-amd64
REM
REM Usage (from the backend directory, where go.mod lives):
REM   build_linux.bat
setlocal

REM Move to the directory this script lives in (the backend module root).
cd /d "%~dp0"

set "OUT_DIR=builds"
set "OUT_NAME=hackit-16-backend-linux-amd64"
set "OUT_PATH=%OUT_DIR%\%OUT_NAME%"

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

REM Best-effort build metadata (empty-safe if git is unavailable).
set "VERSION=dev"
for /f "delims=" %%v in ('git describe --tags --always --dirty 2^>nul') do set "VERSION=%%v"
set "COMMIT=none"
for /f "delims=" %%c in ('git rev-parse --short HEAD 2^>nul') do set "COMMIT=%%c"
for /f "delims=" %%t in ('powershell -NoProfile -Command "(Get-Date).ToUniversalTime().ToString(\"yyyy-MM-ddTHH:mm:ssZ\")"') do set "BUILD_TIME=%%t"

echo Building %OUT_PATH%
echo   version=%VERSION% commit=%COMMIT% time=%BUILD_TIME%

REM Target Linux amd64 with a fully static binary (CGO off).
set "CGO_ENABLED=0"
set "GOOS=linux"
set "GOARCH=amd64"

go build -trimpath -ldflags "-s -w -X main.version=%VERSION% -X main.commit=%COMMIT% -X main.buildTime=%BUILD_TIME%" -o "%OUT_PATH%" ./cmd/api
if errorlevel 1 (
    echo BUILD FAILED
    exit /b 1
)

echo Done: %OUT_PATH%
dir "%OUT_PATH%"
endlocal
