@echo off
title AERO-Q GCS Tactical HUD Simulator
cd /d "%~dp0"
python preview_aeroq_hud.py
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo An error occurred running the preview.
    pause
)

