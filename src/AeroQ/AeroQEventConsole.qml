import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    height: isCollapsed ? ScreenTools.defaultFontPixelHeight * 2.2 : Math.max(ScreenTools.defaultFontPixelHeight * 11, 150)

    property bool isCollapsed: false

    // -------------------------------------------------------------------------
    // Vehicle & Telemetry Connections
    // -------------------------------------------------------------------------
    readonly property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle

    ListModel {
        id: eventLogModel
    }

    function addLog(type, message) {
        var now = new Date()
        var h = now.getHours()
        var m = now.getMinutes()
        var s = now.getSeconds()
        var ms = now.getMilliseconds()
        var timeStr = (h < 10 ? "0" + h : h) + ":" +
                      (m < 10 ? "0" + m : m) + ":" +
                      (s < 10 ? "0" + s : s) + "." +
                      (ms < 100 ? (ms < 10 ? "00" + ms : "0" + ms) : ms)

        eventLogModel.append({
            "timestamp": timeStr,
            "category": type,
            "message": message
        })

        if (eventLogModel.count > 150) {
            eventLogModel.remove(0)
        }

        if (autoScrollCheck.checked) {
            logListView.positionViewAtEnd()
        }
    }

    // Initial system boot log
    Component.onCompleted: {
        addLog("SYS", "AERO-Q Tactical Avionics v2.4 initialized.")
        if (activeVehicle) {
            addLog("SYS", "Linked to Vehicle #" + activeVehicle.id + " (" + activeVehicle.firmwareTypeString + ")")
        } else {
            addLog("SYS", "Telemetry link standby. Waiting for MAVLink heartbeat...")
        }
    }

    // MAVLink Vehicle Event Listeners (Qt6 syntax)
    Connections {
        target: root.activeVehicle
        ignoreUnknownSignals: true

        function onTextMessageReceived(sysid, componentid, severity, text, description) {
            var cat = (severity <= 3) ? "CRIT" : (severity <= 4 ? "WARN" : "MAV")
            root.addLog(cat, text)
        }

        function onArmedChanged() {
            if (root.activeVehicle) {
                if (root.activeVehicle.armed) {
                    root.addLog("WARN", ">>> MOTORS ARMED - PROPELLERS ACTIVE <<<")
                } else {
                    root.addLog("EVENT", "Vehicle disarmed safely.")
                }
            }
        }

        function onFlightModeChanged() {
            if (root.activeVehicle) {
                root.addLog("CMD", "Flight mode transition -> " + root.activeVehicle.flightMode)
            }
        }

        function onCommunicationLostChanged() {
            if (root.activeVehicle) {
                if (root.activeVehicle.communicationLost) {
                    root.addLog("CRIT", "COMMUNICATION LOST - LINK TIMEOUT")
                } else {
                    root.addLog("EVENT", "Communication restored on link.")
                }
            }
        }

        function onInitialPlanRequestCompleteChanged() {
            root.addLog("EVENT", "Vehicle mission plan synchronization complete.")
        }
    }

    // Manager connections for vehicle connect / disconnect
    Connections {
        target: QGroundControl.multiVehicleManager
        ignoreUnknownSignals: true

        function onActiveVehicleChanged(vehicle) {
            if (vehicle) {
                root.addLog("EVENT", "Active vehicle changed -> ID #" + vehicle.id + " (" + vehicle.firmwareTypeString + ")")
            } else {
                root.addLog("WARN", "Vehicle link disconnected. Returning to standby.")
            }
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
        anchors.margins: 6
        spacing: 4

        // ---------------------------------------------------------------------
        // Header & Controls
        // ---------------------------------------------------------------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: qsTr("TACTICAL MAVLINK & EVENT CONSOLE")
                font.family: AeroQTheme.fontFamilyHeader
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                font.bold: true
                color: AeroQTheme.accentCyan
                font.letterSpacing: 0.8
            }

            Rectangle {
                width: 8; height: 8; radius: 4
                color: AeroQTheme.statusArmed
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    PropertyAnimation { from: 1.0; to: 0.2; duration: 900 }
                    PropertyAnimation { from: 0.2; to: 1.0; duration: 900 }
                }
            }

            Item { Layout.fillWidth: true }

            // Auto-scroll toggle
            CheckBox {
                id: autoScrollCheck
                checked: true
                text: qsTr("AUTO-SCROLL")
                font.family: AeroQTheme.fontFamilyMono
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                palette.windowText: AeroQTheme.textSecondary
            }

            // Clear Log Button
            Rectangle {
                width: ScreenTools.defaultFontPixelWidth * 7
                height: ScreenTools.defaultFontPixelHeight * 1.3
                radius: 2
                color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.7)
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: qsTr("CLEAR")
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: AeroQTheme.textSecondary
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: eventLogModel.clear()
                }
            }

            // Collapse / Expand Button
            Rectangle {
                width: ScreenTools.defaultFontPixelWidth * 6
                height: ScreenTools.defaultFontPixelHeight * 1.3
                radius: 2
                color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.7)
                border.color: AeroQTheme.accentCyan
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.isCollapsed ? "▲ EXP" : "▼ MIN"
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.isCollapsed = !root.isCollapsed
                }
            }
        }

        // ---------------------------------------------------------------------
        // Log List View (Visible when not collapsed)
        // ---------------------------------------------------------------------
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.isCollapsed
            color: Qt.rgba(3 / 255, 6 / 255, 13 / 255, 0.75)
            border.color: AeroQTheme.borderDim
            border.width: 1
            clip: true

            ListView {
                id: logListView
                anchors.fill: parent
                anchors.margins: 4
                model: eventLogModel
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                delegate: RowLayout {
                    width: logListView.width - 8
                    spacing: 6

                    // Timestamp
                    Text {
                        text: "[" + model.timestamp + "]"
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.58
                        color: AeroQTheme.textMuted
                        Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 13
                    }

                    // Category Badge
                    Rectangle {
                        width: 44
                        height: ScreenTools.defaultFontPixelHeight * 0.85
                        radius: 2
                        color: model.category === "CRIT" ? Qt.rgba(1, 34 / 255, 68 / 255, 0.25)
                             : (model.category === "WARN" ? Qt.rgba(1, 153 / 255, 0, 0.25)
                             : (model.category === "CMD"  ? Qt.rgba(0, 229 / 255, 1, 0.20)
                             : Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.6)))
                        border.color: model.category === "CRIT" ? AeroQTheme.statusDisarmed
                                    : (model.category === "WARN" ? AeroQTheme.statusWarning
                                    : (model.category === "CMD"  ? AeroQTheme.accentCyan : AeroQTheme.borderBlue))
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: model.category
                            font.family: AeroQTheme.fontFamilyMono
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.50
                            font.bold: true
                            color: model.category === "CRIT" ? AeroQTheme.statusDisarmed
                                 : (model.category === "WARN" ? AeroQTheme.statusWarning
                                 : (model.category === "CMD"  ? AeroQTheme.accentCyan : AeroQTheme.textSecondary))
                        }
                    }

                    // Log Message
                    Text {
                        Layout.fillWidth: true
                        text: model.message
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                        color: model.category === "CRIT" ? AeroQTheme.statusDisarmed
                             : (model.category === "WARN" ? AeroQTheme.statusWarning : AeroQTheme.textPrimary)
                        wrapMode: Text.WrapAnywhere
                    }
                }

                ScrollBar.vertical: ScrollBar {
                    active: true
                    policy: ScrollBar.AsNeeded
                }
            }
        }
    }
}

