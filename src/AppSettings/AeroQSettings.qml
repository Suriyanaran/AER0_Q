import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools
import AeroQ

SettingsPage {
    id: root

    Settings {
        id: aeroSettings
        category: "AeroQ"

        property bool enableTacticalHud:      true
        property bool enableFleetSimulation:  true
        property bool showFpvOverlay:         true
        property real hudOpacity:             0.95
    }

    // -------------------------------------------------------------------------
    // Main Settings Content Layout
    // -------------------------------------------------------------------------
    ColumnLayout {
        Layout.fillWidth: true
        spacing: ScreenTools.defaultFontPixelHeight * 1.2

        // Page Header Banner
        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 4.2
            radius: 4
            color: AeroQTheme.bgGlassDark
            border.color: AeroQTheme.accentCyan
            border.width: 1.2

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    width: ScreenTools.defaultFontPixelHeight * 2.5
                    height: width
                    radius: 4
                    color: Qt.rgba(0, 229 / 255, 1, 0.15)
                    border.color: AeroQTheme.accentCyan
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "⚔"
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 1.4
                    }
                }

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: qsTr("AERO-Q TACTICAL AVIONICS SUITE")
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.90
                        font.bold: true
                        color: AeroQTheme.accentCyan
                    }
                    Text {
                        text: qsTr("Tactical Military Glassmorphic HUD & Overwatch System • v2.4")
                        font.family: AeroQTheme.fontFamilyTelemetry
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                        color: AeroQTheme.textSecondary
                    }
                }
            }
        }

        // =====================================================================
        // SECTION 1: MASTER HUD TOGGLE
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            height: masterLayout.height + 24
            radius: 4
            color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.8)
            border.color: aeroSettings.enableTacticalHud ? AeroQTheme.accentCyan : AeroQTheme.borderDim
            border.width: 1

            ColumnLayout {
                id: masterLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 10

                Text {
                    text: qsTr("TACTICAL HUD DISPLAY")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.70
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: qsTr("Enable Tactical HUD Overlay")
                            font.family: AeroQTheme.fontFamilyTelemetry
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                            font.bold: true
                            color: AeroQTheme.textPrimary
                        }
                        Text {
                            text: qsTr("Renders the military glassmorphic PFD, health matrix, rolling telemetry charts, and MAVLink console in Fly View. When disabled, QGroundControl renders default UI cleanly.")
                            font.family: AeroQTheme.fontFamilyTelemetry
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                            color: AeroQTheme.textSecondary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: aeroSettings.enableTacticalHud
                        onToggled: aeroSettings.enableTacticalHud = checked
                    }
                }

                // Opacity Slider
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    visible: aeroSettings.enableTacticalHud

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: qsTr("HUD Glassmorphic Opacity: %1%").arg(Math.round(aeroSettings.hudOpacity * 100))
                            font.family: AeroQTheme.fontFamilyTelemetry
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                            color: AeroQTheme.textPrimary
                        }
                    }

                    Slider {
                        Layout.fillWidth: true
                        from: 0.40
                        to: 1.00
                        stepSize: 0.05
                        value: aeroSettings.hudOpacity
                        onMoved: aeroSettings.hudOpacity = value
                    }
                }

                // FPV PIP Toggle
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    visible: aeroSettings.enableTacticalHud

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: qsTr("Show FPV Picture-in-Picture by Default")
                            font.family: AeroQTheme.fontFamilyTelemetry
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.70
                            font.bold: true
                            color: AeroQTheme.textPrimary
                        }
                        Text {
                            text: qsTr("Displays floating draggable camera view with tactical OSD overlay.")
                            font.family: AeroQTheme.fontFamilyTelemetry
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                            color: AeroQTheme.textSecondary
                        }
                    }

                    Switch {
                        checked: aeroSettings.showFpvOverlay
                        onToggled: aeroSettings.showFpvOverlay = checked
                    }
                }
            }
        }

        // =====================================================================
        // SECTION 2: FLEET & SIMULATION INTEGRATION
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            height: simLayout.height + 24
            radius: 4
            color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.8)
            border.color: AeroQTheme.borderDim
            border.width: 1

            ColumnLayout {
                id: simLayout
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 12
                spacing: 10

                Text {
                    text: qsTr("FLEET & SIMULATION")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.70
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: qsTr("Enable Fleet & SOS Simulation Mode")
                            font.family: AeroQTheme.fontFamilyTelemetry
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                            font.bold: true
                            color: AeroQTheme.textPrimary
                        }
                        Text {
                            text: qsTr("Populates multi-drone Nano² mesh telemetry and mock emergency queue. Operator approval remains strictly required.")
                            font.family: AeroQTheme.fontFamilyTelemetry
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                            color: AeroQTheme.textSecondary
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }
                    }

                    Switch {
                        checked: aeroSettings.enableFleetSimulation
                        onToggled: aeroSettings.enableFleetSimulation = checked
                    }
                }
            }
        }

        // =====================================================================
        // SECTION 3: DEFAULTS RESET
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 2.2
            radius: 3
            color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.6)
            border.color: AeroQTheme.borderDim
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: qsTr("RESTORE AERO-Q DEFAULT SETTINGS")
                font.family: AeroQTheme.fontFamilyHeader
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                font.bold: true
                color: AeroQTheme.textSecondary
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    aeroSettings.enableTacticalHud = true
                    aeroSettings.enableFleetSimulation = true
                    aeroSettings.showFpvOverlay = true
                    aeroSettings.hudOpacity = 0.95
                }
            }
        }
    }
}

