@echo off
setlocal enabledelayedexpansion
title AERO-Q GCS - Tactical Avionics Suite v2.4
cd /d "%~dp0"

echo ========================================================
echo       AERO-Q GCS - TACTICAL AVIONICS SUITE v2.4
echo ========================================================
echo.

:: 1. Check if compiled standalone executable exists
if exist "%~dp0dist\Aero-q-gcs\Aero-q-gcs.exe" (
    echo [LAUNCH] Found standalone binary. Launching Aero-q-gcs.exe...
    start "" "%~dp0dist\Aero-q-gcs\Aero-q-gcs.exe"
    exit /b 0
)

:: 2. If not precompiled, check if Python is installed
echo [INFO] Standalone binary not found (running from source/ZIP).
echo [CHECK] Checking Python environment...

where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Python 3 was not found on your system!
    echo.
    echo To run Aero-Q GCS:
    echo 1. Download and install Python 3.10+ from https://www.python.org/downloads/
    echo    (Make sure to check "Add python.exe to PATH" during installation)
    echo 2. Run this launcher again!
    echo.
    pause
    exit /b 1
)

:: 3. Check and install dependencies if needed
python -c "import PySide6, pymavlink, serial" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [SETUP] Installing required dependencies (PySide6, pymavlink, pyserial)...
    pip install -r requirements.txt
    if %ERRORLEVEL% NEQ 0 (
        echo [ERROR] Failed to install dependencies. Please run 'pip install -r requirements.txt' manually.
        pause
        exit /b 1
    )
)

:: 4. Launch Desktop Application via Python
echo [LAUNCH] Starting AERO-Q GCS Desktop Application...
python preview_aeroq_hud.py

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo [ERROR] Application exited with an error.
    pause
)
