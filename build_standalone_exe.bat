@echo off
title Build Aero-q-gcs Standalone Executable
cd /d "%~dp0"

echo ========================================================
echo       BUILDING AERO-Q GCS STANDALONE EXECUTABLE
echo ========================================================
echo.

where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python was not found in PATH!
    pause
    exit /b 1
)

echo [1/3] Ensuring build dependencies are installed...
pip install -r requirements.txt pyinstaller

echo.
echo [2/3] Compiling Aero-q-gcs with PyInstaller...
pyinstaller --noconfirm --onedir --windowed --name "Aero-q-gcs" --add-data "src/AeroQ;src/AeroQ" --add-data "tools/mock_qml;tools/mock_qml" preview_aeroq_hud.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================================
    echo [SUCCESS] Build complete!
    echo Executable location: %~dp0dist\Aero-q-gcs\Aero-q-gcs.exe
    echo ========================================================
) else (
    echo.
    echo [ERROR] Build failed! Check the output above.
)

pause

