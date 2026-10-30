import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    height: Math.max(ScreenTools.defaultFontPixelHeight * 2.8, 48)

    // Public signals
    signal toggleFlightControls()
    signal toggleFleetPanel()
    signal toggleSosPanel()
    signal openSettings()

    // -------------------------------------------------------------------------
    // Vehicle & Telemetry Bindings (Defensive Null Checks)
    // -------------------------------------------------------------------------
    readonly property var activeVehicle:   QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool isConnected:    activeVehicle !== null && !activeVehicle.communicationLost
    readonly property bool isArmed:        activeVehicle ? activeVehicle.armed : false
    readonly property string flightMode:   activeVehicle ? activeVehicle.flightMode : "--"

    // Battery telemetry
    readonly property var primaryBattery:  (activeVehicle && activeVehicle.batteries && activeVehicle.batteries.count > 0)
                                           ? activeVehicle.batteries.get(0) : null
    readonly property real batteryVoltage: primaryBattery && primaryBattery.voltage ? primaryBattery.voltage.value : NaN
    readonly property real batteryPercent: primaryBattery && primaryBattery.percentRemaining ? primaryBattery.percentRemaining.value : NaN

    // GPS telemetry
    readonly property real gpsSatCount:    activeVehicle && activeVehicle.gps && activeVehicle.gps.count ? activeVehicle.gps.count.value : NaN
    readonly property string gpsLockStr:   activeVehicle && activeVehicle.gps && activeVehicle.gps.lock ? activeVehicle.gps.lock.enumStringValue : "--"

    // RC telemetry
    readonly property real rcRssi:         activeVehicle && activeVehicle.rcRSSI ? activeVehicle.rcRSSI.value : NaN

    // Flight time tracking
    property int _flightTimerSeconds: 0
    Timer {
        id: flightTimer
        interval: 1000
        repeat: true
        running: root.isConnected && root.isArmed
        onTriggered: root._flightTimerSeconds++
    }

    onIsArmedChanged: {
        if (isArmed && _flightTimerSeconds === 0) {
            _flightTimerSeconds = 0
        }
    }

    // -------------------------------------------------------------------------
    // Visual Background: Glassmorphic Tactical Bar
    // -------------------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: AeroQTheme.bgGlassDark
        border.color: AeroQTheme.borderDim
        border.width: 1

        // Bottom neon cyan accent line
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: AeroQTheme.accentCyan
            opacity: 0.85
        }

        // Subtle gradient top shine
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Qt.rgba(1, 1, 1, 0.15)
        }
    }

    // -------------------------------------------------------------------------
    // Main Bar Content Layout
    // -------------------------------------------------------------------------
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: ScreenTools.defaultFontPixelWidth * 1.5
        anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 1.5
        spacing: ScreenTools.defaultFontPixelWidth * 1.5

        // =====================================================================
        // LEFT: Tactical Branding & System ID
        // =====================================================================
        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth * 0.8
            Layout.alignment: Qt.AlignVCenter

            // Tactical Corner Icon / Logo Mark
            Rectangle {
                width: ScreenTools.defaultFontPixelHeight * 1.6
                height: width
                radius: 3
                color: Qt.rgba(0, 229 / 255, 1, 0.12)
                border.color: AeroQTheme.accentCyan
                border.width: 1

                Canvas {
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext("2d")
                        ctx.reset()
                        ctx.strokeStyle = AeroQTheme.accentCyan
                        ctx.lineWidth = 1.5
                        var cx = width / 2
                        var cy = height / 2
                        // Tactical delta reticle
                        ctx.beginPath()
                        ctx.moveTo(cx, cy - height * 0.35)
                        ctx.lineTo(cx + width * 0.3, cy + height * 0.3)
                        ctx.lineTo(cx, cy + height * 0.15)
                        ctx.lineTo(cx - width * 0.3, cy + height * 0.3)
                        ctx.closePath()
                        ctx.stroke()
                    }
                }
            }

            ColumnLayout {
                spacing: 0

                Text {
                    text: qsTr("AERO-Q GCS")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.95
                    font.bold: true
                    color: AeroQTheme.accentCyan
                    style: Text.Outline
                    styleColor: Qt.rgba(0, 229 / 255, 1, 0.4)
                }

                Text {
                    text: qsTr("Tactical Avionics • Defense Suite v2.4")
                    font.family: AeroQTheme.fontFamilyTelemetry
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                    font.bold: true
                    color: AeroQTheme.textSecondary
                    font.letterSpacing: 0.5
                }
            }

            // System ID Badge
            Rectangle {
                Layout.leftMargin: ScreenTools.defaultFontPixelWidth
                height: ScreenTools.defaultFontPixelHeight * 1.4
                width: sysIdText.contentWidth + ScreenTools.defaultFontPixelWidth * 1.5
                radius: 2
                color: Qt.rgba(31 / 255, 64 / 255, 104 / 255, 0.35)
                border.color: AeroQTheme.borderBlue
                border.width: 1

                Text {
                    id: sysIdText
                    anchors.centerIn: parent
                    text: root.activeVehicle ? qsTr("SYS-ID: %1").arg(root.activeVehicle.id) : qsTr("SYS: OFFLINE")
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                    font.bold: true
                    color: root.isConnected ? AeroQTheme.textCyan : AeroQTheme.textMuted
                }
            }
        }

        Item { Layout.fillWidth: true } // Spacer

        // =====================================================================
        // CENTER: Flight Mode, Armed Pill, & Timer
        // =====================================================================
        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth * 1.2
            Layout.alignment: Qt.AlignVCenter

            // Flight Mode Pill
            Rectangle {
                height: ScreenTools.defaultFontPixelHeight * 1.7
                width: modeText.contentWidth + ScreenTools.defaultFontPixelWidth * 2
                radius: 3
                color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.9)
                border.color: AeroQTheme.accentCyan
                border.width: 1.2

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Rectangle {
                        width: 6; height: 6; radius: 3
                        color: AeroQTheme.accentCyan
                    }

                    Text {
                        id: modeText
                        text: root.flightMode.toUpperCase()
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                        font.bold: true
                        color: AeroQTheme.textPrimary
                        font.letterSpacing: 1.0
                    }
                }
            }

            // ARMED / DISARMED Pill (With Pulsing Glow Animation when Armed)
            Rectangle {
                id: armPill
                height: ScreenTools.defaultFontPixelHeight * 1.7
                width: armText.contentWidth + ScreenTools.defaultFontPixelWidth * 2.2
                radius: 3
                color: root.isArmed ? Qt.rgba(0, 1, 102 / 255, 0.20) : Qt.rgba(1, 34 / 255, 68 / 255, 0.20)
                border.color: root.isArmed ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                border.width: 1.4

                // Pulsing glow animation on border
                SequentialAnimation on border.color {
                    running: root.isArmed
                    loops: Animation.Infinite
                    ColorAnimation { from: AeroQTheme.statusArmed; to: Qt.rgba(0, 1, 102 / 255, 0.35); duration: 800 }
                    ColorAnimation { from: Qt.rgba(0, 1, 102 / 255, 0.35); to: AeroQTheme.statusArmed; duration: 800 }
                }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Rectangle {
                        width: 7; height: 7; radius: 3.5
                        color: root.isArmed ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed

                        // Pulsing dot
                        SequentialAnimation on opacity {
                            running: root.isArmed
                            loops: Animation.Infinite
                            PropertyAnimation { from: 1.0; to: 0.3; duration: 800 }
                            PropertyAnimation { from: 0.3; to: 1.0; duration: 800 }
                        }
                    }

                    Text {
                        id: armText
                        text: root.isArmed ? qsTr("ARMED") : qsTr("DISARMED")
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                        font.bold: true
                        color: root.isArmed ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                        font.letterSpacing: 1.0
                    }
                }
            }

            // Flight Timer
            Rectangle {
                height: ScreenTools.defaultFontPixelHeight * 1.7
                width: timerText.contentWidth + ScreenTools.defaultFontPixelWidth * 2
                radius: 3
                color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.75)
                border.color: AeroQTheme.borderDim
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "⏱"
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.7
                        color: AeroQTheme.textSecondary
                    }

                    Text {
                        id: timerText
                        text: AeroQTheme.formatTimer(root._flightTimerSeconds)
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                        font.bold: true
                        color: root.isArmed ? AeroQTheme.accentCyan : AeroQTheme.textSecondary
                    }
                }
            }
        }

        Item { Layout.fillWidth: true } // Spacer

        // =====================================================================
        // RIGHT: Battery, GPS, RC Link, and Pulsing Status Indicator
        // =====================================================================
        RowLayout {
            spacing: ScreenTools.defaultFontPixelWidth * 1.2
            Layout.alignment: Qt.AlignVCenter

            // Battery Badge
            Rectangle {
                height: ScreenTools.defaultFontPixelHeight * 1.7
                width: batteryLayout.width + ScreenTools.defaultFontPixelWidth * 1.5
                radius: 3
                color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.75)
                border.color: isNaN(root.batteryPercent) ? AeroQTheme.borderDim
                            : (root.batteryPercent < 20 ? AeroQTheme.statusDisarmed : AeroQTheme.borderBlue)
                border.width: 1

                RowLayout {
                    id: batteryLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "⚡"
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                        color: root.batteryPercent < 20 ? AeroQTheme.statusDisarmed : AeroQTheme.statusArmed
                    }

                    Text {
                        text: AeroQTheme.formatPercent(root.batteryPercent)
                        font.family: AeroQTheme.fontFamilyTelemetry
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                        font.bold: true
                        color: root.batteryPercent < 20 ? AeroQTheme.statusDisarmed : AeroQTheme.textPrimary
                    }

                    Text {
                        text: AeroQTheme.formatVoltage(root.batteryVoltage)
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                        color: AeroQTheme.textSecondary
                    }
                }
            }

            // GPS Badge
            Rectangle {
                height: ScreenTools.defaultFontPixelHeight * 1.7
                width: gpsLayout.width + ScreenTools.defaultFontPixelWidth * 1.5
                radius: 3
                color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.75)
                border.color: AeroQTheme.borderDim
                border.width: 1

                RowLayout {
                    id: gpsLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "🛰"
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                        color: AeroQTheme.accentCyan
                    }

                    Text {
                        text: isNaN(root.gpsSatCount) ? "-- SATS" : Math.round(root.gpsSatCount) + " SATS"
                        font.family: AeroQTheme.fontFamilyTelemetry
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                        font.bold: true
                        color: AeroQTheme.textPrimary
                    }

                    Text {
                        text: root.gpsLockStr
                        font.family: AeroQTheme.fontFamilyTelemetry
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                        font.bold: true
                        color: AeroQTheme.textCyan
                    }
                }
            }

            // RC Link RSSI
            Rectangle {
                height: ScreenTools.defaultFontPixelHeight * 1.7
                width: rcLayout.width + ScreenTools.defaultFontPixelWidth * 1.5
                radius: 3
                color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.75)
                border.color: AeroQTheme.borderDim
                border.width: 1

                RowLayout {
                    id: rcLayout
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "📶"
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                        color: AeroQTheme.accentCyan
                    }

                    Text {
                        text: qsTr("RC: ") + AeroQTheme.formatPercent(root.rcRssi)
                        font.family: AeroQTheme.fontFamilyTelemetry
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                        font.bold: true
                        color: AeroQTheme.textPrimary
                    }
                }
            }

            // Pulsing Live Connection Indicator
            Rectangle {
                width: ScreenTools.defaultFontPixelHeight * 1.7
                height: width
                radius: width / 2
                color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.9)
                border.color: root.isConnected ? AeroQTheme.accentCyan : AeroQTheme.statusDisarmed
                border.width: 1

                // Outer animated beacon wave
                Rectangle {
                    id: pulseWave
                    anchors.centerIn: parent
                    width: parent.width * 0.6
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.color: root.isConnected ? AeroQTheme.accentCyan : AeroQTheme.statusDisarmed
                    border.width: 1.5

                    SequentialAnimation on scale {
                        running: true
                        loops: Animation.Infinite
                        PropertyAnimation { from: 0.6; to: 1.4; duration: 1200; easing.type: Easing.OutQuad }
                    }
                    SequentialAnimation on opacity {
                        running: true
                        loops: Animation.Infinite
                        PropertyAnimation { from: 1.0; to: 0.0; duration: 1200; easing.type: Easing.OutQuad }
                    }
                }

                // Inner core LED dot
                Rectangle {
                    anchors.centerIn: parent
                    width: 7; height: 7; radius: 3.5
                    color: root.isConnected ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                }
            }
        }
    }
}

