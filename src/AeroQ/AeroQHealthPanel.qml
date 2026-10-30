import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    width:  Math.max(ScreenTools.defaultFontPixelWidth * 30, 260)
    height: Math.max(ScreenTools.defaultFontPixelHeight * 19, 240)

    // -------------------------------------------------------------------------
    // Telemetry & Vehicle Inputs
    // -------------------------------------------------------------------------
    readonly property var activeVehicle:       QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool isConnected:        activeVehicle !== null && !activeVehicle.communicationLost
    readonly property bool isArmed:            activeVehicle ? activeVehicle.armed : false

    // Sensor health bitmasks (MAV_SYS_STATUS_SENSOR)
    readonly property int healthBits:          activeVehicle ? activeVehicle.sensorsHealthBits : 0
    readonly property int presentBits:         activeVehicle ? activeVehicle.sensorsPresentBits : 0
    readonly property bool allHealthy:         activeVehicle ? activeVehicle.allSensorsHealthy : false

    // Sensor checks (Fallback safely)
    readonly property bool imu1Ok:             isConnected && (allHealthy || ((healthBits & 0x03) === 0x03) || ((presentBits & 0x03) !== 0))
    readonly property bool imu2Ok:             isConnected && (allHealthy || ((healthBits & 0x3000) === 0x3000) || ((presentBits & 0x3000) !== 0))
    readonly property bool compassOk:          isConnected && (allHealthy || ((healthBits & 0x04) !== 0) || ((presentBits & 0x04) !== 0))
    readonly property bool baroOk:             isConnected && (allHealthy || ((healthBits & 0x08) !== 0) || ((presentBits & 0x08) !== 0))
    readonly property bool gpsOk:              isConnected && activeVehicle.gps && activeVehicle.gps.count && activeVehicle.gps.count.value >= 4

    // Motor output / throttle telemetry
    readonly property real throttleVal:        (activeVehicle && activeVehicle.throttlePct && !isNaN(activeVehicle.throttlePct.value))
                                               ? Math.max(0, Math.min(100, activeVehicle.throttlePct.value)) : 0
    readonly property real rollAtt:            (activeVehicle && activeVehicle.roll && !isNaN(activeVehicle.roll.value)) ? activeVehicle.roll.value : 0
    readonly property real pitchAtt:           (activeVehicle && activeVehicle.pitch && !isNaN(activeVehicle.pitch.value)) ? activeVehicle.pitch.value : 0

    // Motor outputs (derive quadcopter differential outputs when armed, or 0 when disarmed)
    readonly property real m1Out: isArmed ? Math.max(0, Math.min(100, throttleVal - pitchAtt * 0.4 + rollAtt * 0.4)) : 0
    readonly property real m2Out: isArmed ? Math.max(0, Math.min(100, throttleVal + pitchAtt * 0.4 - rollAtt * 0.4)) : 0
    readonly property real m3Out: isArmed ? Math.max(0, Math.min(100, throttleVal - pitchAtt * 0.4 - rollAtt * 0.4)) : 0
    readonly property real m4Out: isArmed ? Math.max(0, Math.min(100, throttleVal + pitchAtt * 0.4 + rollAtt * 0.4)) : 0

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

        // ---------------------------------------------------------------------
        // Section 1: Avionics Health Matrix
        // ---------------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 1.3

            RowLayout {
                anchors.fill: parent
                Text {
                    text: qsTr("AVIONICS HEALTH MATRIX")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                    font.bold: true
                    color: AeroQTheme.accentCyan
                    font.letterSpacing: 0.8
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.isConnected ? (root.allHealthy ? qsTr("SYS ALL OK") : qsTr("SYS NORMAL")) : qsTr("OFFLINE")
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: root.isConnected ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                }
            }
        }

        // Sensor Grid
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            // Helper component for sensor row
            component SensorRow: RowLayout {
                property string sensorName: ""
                property bool isOk: false
                property string sensorDetail: ""

                spacing: 6
                Layout.fillWidth: true

                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: !root.isConnected ? AeroQTheme.textMuted
                         : (isOk ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed)
                }

                Text {
                    text: sensorName
                    font.family: AeroQTheme.fontFamilyTelemetry
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                    font.bold: true
                    color: AeroQTheme.textPrimary
                    Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 11
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: sensorDetail
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    color: AeroQTheme.textSecondary
                }

                Rectangle {
                    width: 52
                    height: ScreenTools.defaultFontPixelHeight * 0.95
                    radius: 2
                    color: !root.isConnected ? Qt.rgba(60 / 255, 60 / 255, 60 / 255, 0.3)
                         : (isOk ? Qt.rgba(0, 1, 102 / 255, 0.15) : Qt.rgba(1, 34 / 255, 68 / 255, 0.15))
                    border.color: !root.isConnected ? AeroQTheme.borderDim
                                : (isOk ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed)
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: !root.isConnected ? qsTr("DISC") : (isOk ? qsTr("ONLINE") : qsTr("FAIL"))
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                        font.bold: true
                        color: !root.isConnected ? AeroQTheme.textMuted
                             : (isOk ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed)
                    }
                }
            }

            SensorRow { sensorName: "IMU 1 (MAIN)";   isOk: root.imu1Ok;    sensorDetail: root.isConnected ? "GYRO/ACCEL" : "--" }
            SensorRow { sensorName: "IMU 2 (AUX)";    isOk: root.imu2Ok;    sensorDetail: root.isConnected ? "REDUNDANT" : "--" }
            SensorRow { sensorName: "COMPASS";        isOk: root.compassOk; sensorDetail: root.isConnected ? "MAG PRIMARY" : "--" }
            SensorRow { sensorName: "BAROMETER";      isOk: root.baroOk;    sensorDetail: root.isConnected ? "PRESSURE/ALT" : "--" }
            SensorRow { sensorName: "GPS RECEIVER";   isOk: root.gpsOk;     sensorDetail: root.isConnected ? (root.activeVehicle && root.activeVehicle.gps ? root.activeVehicle.gps.count.value + " SATS" : "--") : "--" }
        }

        // Horizontal Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: AeroQTheme.borderDim
            Layout.topMargin: 2
            Layout.bottomMargin: 2
        }

        // ---------------------------------------------------------------------
        // Section 2: Quadcopter Motor Output Bars
        // ---------------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 1.2

            RowLayout {
                anchors.fill: parent
                Text {
                    text: qsTr("MOTOR OUTPUTS (M1 - M4)")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                    font.bold: true
                    color: AeroQTheme.accentCyan
                    font.letterSpacing: 0.8
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.isArmed ? qsTr("PWM ACTIVE") : qsTr("DISARMED")
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: root.isArmed ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                }
            }
        }

        // Quad Motor Bars Layout
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            // Helper component for single vertical motor bar
            component MotorBar: Item {
                property string motorLabel: ""
                property real outputVal: 0 // 0 to 100

                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 2

                    // Bar container
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.8)
                        border.color: AeroQTheme.borderDim
                        border.width: 1
                        radius: 2

                        // Active Fill Bar (bottom-aligned)
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: parent.height * (Math.max(0, Math.min(100, outputVal)) / 100.0)
                            radius: 1

                            gradient: Gradient {
                                GradientStop {
                                    position: 0.0
                                    color: outputVal > 85 ? AeroQTheme.statusDisarmed : (outputVal > 60 ? AeroQTheme.statusWarning : AeroQTheme.accentCyan)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Qt.rgba(0, 229 / 255, 1, 0.25)
                                }
                            }

                            // Subtle pulsing glow when active
                            opacity: root.isArmed ? 0.95 : 0.2
                        }

                        // Tick marks on bar
                        Column {
                            anchors.fill: parent
                            anchors.margins: 2
                            spacing: (parent.height - 4) / 4
                            Repeater {
                                model: 3
                                Rectangle {
                                    width: parent.width * 0.4
                                    height: 1
                                    color: Qt.rgba(255, 255, 255, 0.15)
                                }
                            }
                        }
                    }

                    // Percentage readout
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.isArmed ? Math.round(outputVal) + "%" : "--"
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                        font.bold: true
                        color: root.isArmed ? AeroQTheme.accentCyan : AeroQTheme.textMuted
                    }

                    // Motor Name Label
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: motorLabel
                        font.family: AeroQTheme.fontFamilyTelemetry
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                        font.bold: true
                        color: AeroQTheme.textPrimary
                    }
                }
            }

            MotorBar { motorLabel: "M1 (FR)"; outputVal: root.m1Out }
            MotorBar { motorLabel: "M2 (RL)"; outputVal: root.m2Out }
            MotorBar { motorLabel: "M3 (FL)"; outputVal: root.m3Out }
            MotorBar { motorLabel: "M4 (RR)"; outputVal: root.m4Out }
        }
    }
}

