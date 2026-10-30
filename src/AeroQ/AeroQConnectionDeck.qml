import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    width:  Math.max(ScreenTools.defaultFontPixelWidth * 30, 260)
    height: Math.max(ScreenTools.defaultFontPixelHeight * 12, 160)

    // -------------------------------------------------------------------------
    // Vehicle & Telemetry Bindings
    // -------------------------------------------------------------------------
    readonly property var activeVehicle:        QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool isConnected:         activeVehicle !== null && !activeVehicle.communicationLost
    readonly property int vehicleId:            activeVehicle ? activeVehicle.id : -1
    readonly property string firmwareStr:       activeVehicle ? activeVehicle.firmwareTypeString : "--"
    readonly property string vehicleTypeStr:    activeVehicle ? activeVehicle.vehicleTypeString : "--"

    // Packet loss & link quality
    readonly property real lossPercent:         (activeVehicle && !isNaN(activeVehicle.mavlinkLossPercent))
                                                ? Math.max(0, Math.min(100, activeVehicle.mavlinkLossPercent)) : 0
    readonly property real linkQuality:         isConnected ? Math.max(0, 100 - lossPercent) : 0

    // Counters
    readonly property real txCount:             activeVehicle ? activeVehicle.mavlinkSentCount : 0
    readonly property real rxCount:             activeVehicle ? activeVehicle.mavlinkReceivedCount : 0
    readonly property real dropCount:           activeVehicle ? activeVehicle.mavlinkLossCount : 0

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
        spacing: 5

        // Header
        Item {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 1.3

            RowLayout {
                anchors.fill: parent
                Text {
                    text: qsTr("MAVLINK CONNECTION DECK")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                    font.bold: true
                    color: AeroQTheme.accentCyan
                    font.letterSpacing: 0.8
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: statusText.contentWidth + 12
                    height: ScreenTools.defaultFontPixelHeight * 0.95
                    radius: 2
                    color: root.isConnected ? Qt.rgba(0, 1, 102 / 255, 0.15) : Qt.rgba(1, 34 / 255, 68 / 255, 0.15)
                    border.color: root.isConnected ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                    border.width: 1

                    Text {
                        id: statusText
                        anchors.centerIn: parent
                        text: root.isConnected ? qsTr("CONNECTED") : qsTr("DISCONNECTED")
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                        font.bold: true
                        color: root.isConnected ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                    }
                }
            }
        }

        // Link Quality Bar
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: qsTr("LINK QUALITY")
                    font.family: AeroQTheme.fontFamilyTelemetry
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                    font.bold: true
                    color: AeroQTheme.textPrimary
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.isConnected ? Math.round(root.linkQuality) + "%" : "--"
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                    font.bold: true
                    color: root.linkQuality > 80 ? AeroQTheme.statusArmed : (root.linkQuality > 50 ? AeroQTheme.statusWarning : AeroQTheme.statusDisarmed)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 6
                radius: 2
                color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.8)
                border.color: AeroQTheme.borderDim
                border.width: 1

                Rectangle {
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.margins: 1
                    width: parent.width * (root.linkQuality / 100.0)
                    radius: 1
                    color: root.linkQuality > 80 ? AeroQTheme.statusArmed : (root.linkQuality > 50 ? AeroQTheme.statusWarning : AeroQTheme.statusDisarmed)
                }
            }
        }

        // Vehicle Metadata Grid
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Vehicle ID Box
            Rectangle {
                Layout.fillWidth: true
                height: ScreenTools.defaultFontPixelHeight * 2.2
                radius: 2
                color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.45)
                border.color: AeroQTheme.borderDim
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                        text: qsTr("VEHICLE ID")
                        font.family: AeroQTheme.fontFamilyTelemetry
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.50
                        color: AeroQTheme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: root.vehicleId >= 0 ? qsTr("SYS #%1").arg(root.vehicleId) : "--"
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.70
                        font.bold: true
                        color: root.isConnected ? AeroQTheme.accentCyan : AeroQTheme.textMuted
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            // Firmware Type Box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredWidth: parent.width * 0.55
                height: ScreenTools.defaultFontPixelHeight * 2.2
                radius: 2
                color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.45)
                border.color: AeroQTheme.borderDim
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 1
                    Text {
                        text: qsTr("FIRMWARE")
                        font.family: AeroQTheme.fontFamilyTelemetry
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.50
                        color: AeroQTheme.textSecondary
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: root.isConnected ? root.firmwareStr : "--"
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                        font.bold: true
                        color: root.isConnected ? AeroQTheme.textPrimary : AeroQTheme.textMuted
                        Layout.alignment: Qt.AlignHCenter
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Packet Diagnostics (TX / RX / Drop)
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: qsTr("TX: ") + (root.isConnected ? root.txCount : "--")
                font.family: AeroQTheme.fontFamilyMono
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                color: AeroQTheme.textSecondary
            }
            Item { Layout.fillWidth: true }
            Text {
                text: qsTr("RX: ") + (root.isConnected ? root.rxCount : "--")
                font.family: AeroQTheme.fontFamilyMono
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                color: AeroQTheme.textSecondary
            }
            Item { Layout.fillWidth: true }
            Text {
                text: qsTr("LOST: ") + (root.isConnected ? root.dropCount : "--")
                font.family: AeroQTheme.fontFamilyMono
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                color: root.dropCount > 0 ? AeroQTheme.statusWarning : AeroQTheme.textSecondary
            }
        }
    }
}

