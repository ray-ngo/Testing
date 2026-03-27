@echo off
setlocal ENABLEDELAYEDEXPANSION

REM Install uv (if missing)
where uv >NUL 2>&1
if errorlevel 1 (
    echo uv not found, installing with PowerShell...
    REM powershell -ExecutionPolicy Bypass -File .\uv-installer.ps1
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
)

REM Ensure current session can find uv.exe (default installer path)
set "PATH=%USERPROFILE%\.local\bin;%PATH%"

REM Simple check
where uv >NUL 2>&1
if errorlevel 1 (
    echo Failed to locate uv after installation. Make sure %USERPROFILE%\.local\bin is on PATH and run this script again.
    exit /b 1
)

REM Create target directory if it doesn't exist
if not exist "C:\Users\%username%\gen3_model151" (
    mkdir "C:\Users\%username%\gen3_model151"
)

REM Copy project files from D:\uv\shared
copy /Y ".python-version" "C:\Users\%username%\gen3_model151\"
copy /Y "pyproject.toml" "C:\Users\%username%\gen3_model151\"
copy /Y "uv.lock" "C:\Users\%username%\gen3_model151\"

REM Change to new project directory
cd /d "C:\Users\%username%\gen3_model151"

REM Sync environment using the provided files
uv sync --locked

endlocal
exit /b 0
