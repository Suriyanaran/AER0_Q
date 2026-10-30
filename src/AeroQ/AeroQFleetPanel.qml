import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    width:  Math.max(ScreenTools.defaultFontPixelWidth * 32, 280)
    height: Math.max(ScreenTools.defaultFontPixelHeight * 22, 280)

    // Feature flag: simulation mock data only
    property bool enableFleetSimulation: true

    // -------------------------------------------------------------------------
    // Fleet Mock Model
    // -------------------------------------------------------------------------
    ListModel {
        id: fleetModel
        ListElement {
            callsign: "AERO-01 Alpha"
            status: "AIRBORNE / PATROL"
            battery: 86
            meshStatus: "MESH N1 OK"
            rssi: 96
            latency: 12
        }
        ListElement {
            callsign: "AERO-02 Bravo"
            status: "LOITER / RECON"
            battery: 74
            meshStatus: "MESH N2 OK"
            rssi: 91
            latency: 18
        }
        ListElement {
            callsign: "AERO-03 Charlie"
            status: "STANDBY / PAD 1"
            battery: 100
            meshStatus: "MESH N3 READY"
            rssi: 99
            latency: 8
        }
        ListElement {
            callsign: "AERO-04 Delta"
            status: "RTL / RETURNING"
            battery: 22
            meshStatus: "MESH N4 LINK"
            rssi: 76
            latency: 28
        }
    }

    // -------------------------------------------------------------------------
    // Background Frame
    // -------------------------------------------------------------------------
    Rectangle {
        anchors.fill: parent
        color: AeroQTheme.bgGlassDark
        border.color: AeroQTheme.borderDim
        border.width: 1
        radius: 4

        // Top cyan header accent
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 2
            color: AeroQTheme.accentCyan
            opacity: 0.85
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        // Header
        Item {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 1.3

            RowLayout {
                anchors.fill: parent
                Text {
                    text: qsTr("TACTICAL FLEET OVERWATCH")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                    font.bold: true
                    color: AeroQTheme.accentCyan
                    font.letterSpacing: 0.8
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: simBadgeText.contentWidth + 10
                    height: ScreenTools.defaultFontPixelHeight * 0.95
                    radius: 2
                    color: Qt.rgba(255 / 255, 153 / 255, 0, 0.15)
                    border.color: AeroQTheme.statusWarning
                    border.width: 1
                    Text {
                        id: simBadgeText
                        anchors.centerIn: parent
                        text: qsTr("SIMULATION")
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.50
                        font.bold: true
                        color: AeroQTheme.statusWarning
                    }
                }
            }
        }

        // Nano² Mesh Topology Status Banner
        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 1.6
            radius: 2
            color: Qt.rgba(0, 229 / 255, 1, 0.08)
            border.color: AeroQTheme.borderBlue
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 6

                Text { text: "☊"; color: AeroQTheme.accentCyan; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.7 }
                Text {
                    text: qsTr("Nano² Mesh: 4 Nodes Active • Ad-Hoc Sync")
                    font.family: AeroQTheme.fontFamilyTelemetry
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                    font.bold: true
                    color: AeroQTheme.textPrimary
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: qsTr("Avg Lat: 16ms")
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    color: AeroQTheme.statusArmed
                }
            }
        }

        // Fleet List
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.enableFleetSimulation ? fleetModel : 0
            spacing: 5
            clip: true

            delegate: Rectangle {
                width: parent.width
                height: ScreenTools.defaultFontPixelHeight * 3.4
                radius: 2
                color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.65)
                border.color: AeroQTheme.borderDim
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 2

                    // Top Row: Callsign & Status Pill
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: model.callsign
                            font.family: AeroQTheme.fontFamilyHeader
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                            font.bold: true
                            color: AeroQTheme.textPrimary
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: model.status
                            font.family: AeroQTheme.fontFamilyMono
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                            font.bold: true
                            color: model.battery < 25 ? AeroQTheme.statusDisarmed : AeroQTheme.accentCyan
                        }
                    }

                    // Bottom Row: Battery, Mesh Node, RSSI, Latency
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            text: "⚡ " + model.battery + "%"
                            font.family: AeroQTheme.fontFamilyMono
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                            color: model.battery < 25 ? AeroQTheme.statusDisarmed : AeroQTheme.statusArmed
                        }

                        Text {
                            text: "🌐 " + model.meshStatus
                            font.family: AeroQTheme.fontFamilyMono
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                            color: AeroQTheme.textSecondary
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: "📶 " + model.rssi + "%"
                            font.family: AeroQTheme.fontFamilyMono
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                            color: AeroQTheme.accentCyan
                        }

                        Text {
                            text: model.latency + "ms"
                            font.family: AeroQTheme.fontFamilyMono
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                            color: AeroQTheme.textMuted
                        }
                    }
                }
            }
        }
    }
}

