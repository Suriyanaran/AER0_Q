# ⚡ AERO-Q GCS — Tactical Avionics & Defense Suite v2.4

<p align="center">
  <b>Advanced Military-Grade Cyberpunk Tactical HUD & Ground Control Station</b><br>
  <i>Built as an additive, non-destructive layer on top of official open-source QGroundControl</i>
</p>

---

## 📑 Table of Contents
1. [Overview](#-overview)
2. [Quick Launch (How to Run)](#-quick-launch-how-to-run)
3. [UI Architecture & Cyberpunk HUD Features](#-ui-architecture--cyberpunk-hud-features)
   - [Left Panel: Tactical PFD / EFIS](#1-tactical-pfd--efis-primary-flight-display)
   - [Interactive Map Engine](#2-interactive-live-map-engine)
   - [Top Status Deck](#3-top-tactical-status-deck)
   - [Right Panel: Health Matrix & Telemetry Chart](#4-right-avionics-deck)
   - [Bottom Panel: Tactical Event Console](#5-bottom-mavlink--event-console)
   - [Flight Controls & Safety Dialogs](#6-flight-controls--safety-modals)
   - [Floating FPV Camera Overlay](#7-floating-fpv-camera-overlay)
   - [Fleet Overwatch & SOS Emergency Queue](#8-fleet-overwatch--sos-emergency-queue)
4. [Connecting a Real Drone (Step-by-Step)](#-connecting-a-real-drone-step-by-step)
   - [Method 1: USB Telemetry Radio (SiK 433MHz / 915MHz)](#method-1-usb-telemetry-radio-sik-433mhz--915mhz--outdoor-flying)
   - [Method 2: Direct USB Cable (Bench Testing)](#method-2-direct-usb-cable--bench-testing)
   - [Method 3: Wi-Fi / Companion Computer (UDP 14550)](#method-3-wi-fi--companion-computer-raspberry-pi--jetson--esp32)
   - [Method 4: Virtual Drone SITL Simulator](#method-4-virtual-drone-sitl-simulator)
5. [Responsive Sizing & Fullscreen](#-responsive-sizing--fullscreen)
6. [QGroundControl Upstream Integration](#-qgroundcontrol-upstream-integration)
7. [Developer & Build Guide](#-developer--build-guide)

---

## 🌟 Overview

**AERO-Q GCS** transforms QGroundControl into a cutting-edge tactical flight operations suite styled with a **cyberpunk / military glassmorphism aesthetic**:
* **Palette**: Deep Obsidian (`#03060d`), Aerospace Blue (`#070c17`), Electric Cyan (`#00e5ff`), Neon Tactical Green (`#00ff66`), Amber Warning (`#ff9900`), and Failsafe Crimson (`#ff2244`).
* **Additive Overlay**: Does **NOT** rewrite QGC or break upstream MAVLink, mission planning, parameter trees, or safety architectures.
* **Fail-Safe Telemetry**: Seamlessly hooks into real vehicle FactSystem properties without fake telemetry (`"--"` shown when disconnected).
* **Dual-Mode Engine**: Operates as a standalone executable (`Aero-q-gcs.exe`) and also directly compiles into native C++ QGC.

---

## 📥 How to Run After Downloading ZIP from GitHub

When downloading the source code from GitHub as a ZIP file (`Code -> Download ZIP`), the large 400MB compiled binary folder (`dist/`) is excluded for lightweight repository sizing. 

You can run the app in **one simple step**:

### ⚡ Method 1: Automatic 1-Click Launcher (Recommended)
1. **Extract** the downloaded `.zip` file.
2. Ensure you have **Python 3.10+** installed on your Windows machine ([Download Python](https://www.python.org/downloads/) — *make sure to check "Add Python to PATH"*).
3. **Double-click `Launch_Aero-q-gcs.bat`** in the extracted folder.
   - The launcher automatically installs any missing dependencies (`PySide6`, `pymavlink`, `pyserial` from `requirements.txt`).
   - The application starts up immediately!

---

### 💻 Method 2: Manual Terminal Run
Open PowerShell or Command Prompt inside the extracted folder:
```powershell
# 1. Install dependencies
pip install -r requirements.txt

# 2. Launch the desktop application
python preview_aeroq_hud.py
```

---

### 🛠️ Method 3: Build Your Own Standalone `.exe`
If you want to bundle it into a standalone `Aero-q-gcs.exe` executable on your computer:
* Double-click **`build_standalone_exe.bat`**, OR run:
```powershell
pip install -r requirements.txt pyinstaller
pyinstaller --noconfirm --onedir --windowed --name "Aero-q-gcs" --add-data "src/AeroQ;src/AeroQ" --add-data "tools/mock_qml;tools/mock_qml" preview_aeroq_hud.py
```
Your ready-to-use `.exe` will be generated in `dist\Aero-q-gcs\Aero-q-gcs.exe`.

---

### 🎁 Tip for GitHub Releases (Pre-built Binaries)
For non-developer users who don't have Python installed:
* You can ZIP your local `dist\Aero-q-gcs\` folder and upload it under your GitHub repository's **Releases** tab.
* Anyone can download the release ZIP, extract it, and double-click `Aero-q-gcs.exe` without installing Python or compilers!

---

## 🖥️ UI Architecture & Cyberpunk HUD Features

### 1. Tactical PFD / EFIS (Primary Flight Display)
Located on the left side of the screen. Features a full 3D Cyberpunk Wireframe design:
* **Wireframe Horizon**: Deep obsidian black space on top, with a 3D perspective wireframe grid receding into the horizon on the bottom.
* **Electric Cyan Horizon Beam**: Dual-glow beam with zero-degree pitch indicators (`00`).
* **Pitch Ladder (-30° to +30°)**: Digital tick marks with numeric pitch readings (`+10`, `+20`, `-10`, `-20`).
* **Aircraft Boresight**: Neon cyan tactical flight path vector chevron.
* **Airspeed & Altitude Tapes**: Dynamic rolling vertical tape scales with digital readouts.
* **Roll Arc**: Top arc indicator displaying bank angles up to ±60°.
* **Toggle Button**: Click **`[PFD]`** in the top-left toolbar to show/hide the PFD instantly.

### 2. Interactive Live Map Engine
A rich real-world GIS map sits underneath the glassmorphic HUD:
* **Multi-Style Switcher**: Toggle on-the-fly between:
  - **`STREET`**: OpenStreetMap roads, cities, and landmarks.
  - **`SATELLITE`**: High-resolution aerial imagery.
  - **`NIGHT / TRANSIT`**: Cyberpunk dark tactical recon map.
* **Interactive Navigation**:
  - **Left-Click + Drag**: Pan anywhere on the map.
  - **Mouse Wheel**: Smooth zoom in and out.
  - **`[+]` / `[-]` Buttons**: Quick zoom increments.
  - **`🎯 RECENTER` Button**: Snaps the map view directly back to the drone and re-engages live tracking.
* **Tactical Drone Glyph**: Rotates in real time matching the drone's true compass heading with a pulsing cyan radar wave, altitude tag, and cyan flight path breadcrumb trail (`MapPolyline`).

### 3. Top Tactical Status Deck
* **Brand Callout**: `AERO-Q GCS | Tactical Avionics • Defense Suite v2.4`.
* **Flight Mode Pill**: Active autopilot mode (`LOITER`, `ALT HOLD`, `AUTO`, `RTL`, `GUIDED`).
* **Arming State Indicator**: Neon green for `ARMED`, glowing red for `DISARMED`.
* **Telemetry Monitors**: Live Battery %, Voltage, GPS Satellite Count, Fix Type (`3D FIX`, `RTK`), and RC RSSI %.
* **Mission Timer**: Elapsed flight duration in `HH:MM:SS`.

### 4. Right Avionics Deck
* **Avionics Health Matrix**: Real-time sensor statuses for IMU 1 (Main), IMU 2 (Aux), Compass, Barometer, and GPS Receiver.
* **Quadcopter Motor Output Bars**: Dynamic vertical bars representing output throttle on motors M1, M2, M3, and M4.
* **Rolling Telemetry Chart**: Real-time canvas graphing relative altitude and groundspeed history over time.
* **MAVLink Connection Deck**: Vehicle ID, Firmware Type string, packet loss counters, and live data rate.

### 5. Bottom MAVLink & Event Console
* **Scrolling Event Log**: Timestamped terminal stream displaying system boots, telemetry sync, arming events, flight mode transitions, and failsafe warnings.
* **Interactive Controls**: Auto-scroll toggle, Log Clear button, and Minimize button.

### 6. Flight Controls & Safety Modals
Click **`[FLIGHT CTRL]`** in the drawer to open:
* Direct flight mode switches: `LOITER`, `ALT HOLD`, `STABILIZE`, `AUTO MISSION`, `RTL`, `LAND`.
* Armed/Disarmed toggles and Guided Takeoff altitude stepper.
* **Mandatory Operator Confirmation**: Every mission-critical action requires a two-step confirmation dialog to prevent accidental triggers.

### 7. Floating FPV Camera Overlay
* Picture-in-Picture floating video feed window with synthetic FLIR / EO sensor reticle fallback.
* Draggable anywhere across the screen, with minimize (`▼`) and close controls.

### 8. Fleet Overwatch & SOS Emergency Queue
* **`[FLEET]`**: Multi-UAV status monitoring table (Callsign, Status, Battery %, Mesh sync, RSSI).
* **`[SOS]`**: Emergency dispatch queue displaying requester coordinates and operator approval buttons.

---

## 📡 Connecting a Real Drone (Step-by-Step)

The **`Aero-q-gcs`** background communications daemon automatically monitors both serial COM ports and network UDP sockets.

### Method 1: USB Telemetry Radio (SiK 433MHz / 915MHz) — *Outdoor Flying*
1. Connect the **Air Telemetry Module** to the Pixhawk / ArduPilot / PX4 `TELEM1` or `TELEM2` port on the drone.
2. Insert the **Ground Telemetry Radio (USB dongle)** into your laptop's USB port.
3. Power on the drone by connecting its LiPo flight battery.
4. Launch **`Aero-q-gcs`**:
   - The app scans all available COM ports (`COM3`, `COM4`, etc.) at **57600 baud**.
   - As soon as the radio LEDs transition to solid green, the connection deck connects and live telemetry streams immediately!

### Method 2: Direct USB Cable — *Bench Testing*
1. Connect a USB-C or Micro-USB cable from your Flight Controller directly to your PC.
2. Launch **`Aero-q-gcs`**:
   - The app scans and locks onto the flight controller's virtual serial port at **115200 baud**.
   - All sensors, compass calibrations, and motor signals will register live.

### Method 3: Wi-Fi / Companion Computer (Raspberry Pi / Jetson / ESP32)
1. Ensure your laptop is connected to the same Wi-Fi network as the drone (or drone Wi-Fi hotspot).
2. Configure MAVProxy, `mavlink-router`, or ESP MAVLink bridge to forward packets to your laptop's IP on port **`14550` (UDP)**.
3. **`Aero-q-gcs`** continuously listens on `0.0.0.0:14550` and will instantly sync the telemetry stream.

### Method 4: Virtual Drone (SITL Simulator)
If you don't have physical hardware on hand:
```bash
# ArduPilot SITL
sim_vehicle.py -v ArduCopter --console --map

# Or PX4 SITL
make px4_sitl jmavsim
```
SITL transmits MAVLink over UDP 14550 by default; **`Aero-q-gcs`** will immediately track the simulated drone in real time.

---

## 📐 Responsive Sizing & Fullscreen

`Aero-q-gcs` utilizes `QQuickView.ResizeMode.SizeRootObjectToView`:
* **Zero Black Bars**: Maximizing the window automatically scales all QML layers to fill 100% of your screen (1080p, 2K, 4K, ultrawide).
* **Anchoring**: The Top Bar stretches end-to-end, the right telemetry deck anchors flush to the right edge, the bottom console spans the bottom, and the interactive map fills all background space.

---

## 🧩 QGroundControl Upstream Integration

The Aero-Q HUD is registered into QGroundControl's official Fly View customization architecture:
* **Custom Layer Injection**: Mounted cleanly in [`src/FlyView/FlyViewCustomLayer.qml`](file:///C:/Users/SURYA%20P/Aero_Q/qgroundcontrol/src/FlyView/FlyViewCustomLayer.qml).
* **Settings Toggle**: Added under **Settings → Aero-Q** ([`src/AppSettings/AeroQSettings.qml`](file:///C:/Users/SURYA%20P/Aero_Q/qgroundcontrol/src/AppSettings/AeroQSettings.qml)). Disabling it restores the standard QGC interface seamlessly.
* **Component Directory**: Modular code stored under [`src/AeroQ/`](file:///C:/Users/SURYA%20P/Aero_Q/qgroundcontrol/src/AeroQ/) with its own `CMakeLists.txt` and `qmldir`.
* **Binary Name**: Branded target updated in [`cmake/CustomOptions.cmake`](file:///C:/Users/SURYA%20P/Aero_Q/qgroundcontrol/cmake/CustomOptions.cmake) to `Aero-q-gcs`.

---

## 🛠️ Developer & Build Guide

### Running in Development (Python / PySide6)
```powershell
python preview_aeroq_hud.py
```

### Rebuilding the Standalone Package
```powershell
pyinstaller --noconfirm --onedir --windowed --name "Aero-q-gcs" --add-data "src/AeroQ;src/AeroQ" --add-data "tools/mock_qml;tools/mock_qml" preview_aeroq_hud.py
```

### Compiling Native C++ QGroundControl
If you have Qt 6 MSVC SDK installed:
```powershell
cmake -B build -G "Visual Studio 18 2026" -A x64 -DCMAKE_PREFIX_PATH="C:\Qt\6.x.x\msvc2022_64"
cmake --build build --config Release --target Aero-q-gcs
```

---

## 🔒 Safety & Operator Guidelines
* **Arming Safeguard**: Never arm propellers indoors with physical blades attached.
* **Dual Action**: Guided Takeoff and Return-to-Launch commands require explicit operator confirmation before transmission.
* **Failsafe Monitoring**: In case of MAVLink loss, the HUD transitions to a crimson failsafe visual state.
