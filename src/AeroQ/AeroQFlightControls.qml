import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    width:  Math.max(ScreenTools.defaultFontPixelWidth * 32, 280)
    height: Math.max(ScreenTools.defaultFontPixelHeight * 24, 320)

    // -------------------------------------------------------------------------
    // Vehicle Telemetry & Capabilities
    // -------------------------------------------------------------------------
    readonly property var activeVehicle: QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool isConnected:  activeVehicle !== null && !activeVehicle.communicationLost
    readonly property bool isArmed:      activeVehicle ? activeVehicle.armed : false
    readonly property string curMode:    activeVehicle ? activeVehicle.flightMode : ""

    // Takeoff altitude parameter (meters)
    property real takeoffAltitude: 10.0

    // Confirmation dialog state
    property bool confirmDialogOpen: false
    property string confirmTitle: ""
    property string confirmMessage: ""
    property color confirmAccentColor: AeroQTheme.statusWarning
    property var confirmActionCallback: null

    function requestActionConfirmation(title, message, accentColor, callback) {
        confirmTitle = title
        confirmMessage = message
        confirmAccentColor = accentColor
        confirmActionCallback = callback
        confirmDialogOpen = true
    }

    function cancelActionConfirmation() {
        confirmDialogOpen = false
        confirmActionCallback = null
    }

    function executeConfirmedAction() {
        confirmDialogOpen = false
        if (confirmActionCallback) {
            confirmActionCallback()
            confirmActionCallback = null
        }
    }

    // Flight mode helper: search best matching mode name from vehicle.flightModes
    function setVehicleFlightMode(desiredMode) {
        if (!activeVehicle) return
        var modes = activeVehicle.flightModes
        var matched = ""
        for (var i = 0; i < modes.length; i++) {
            if (modes[i].toUpperCase() === desiredMode.toUpperCase()) {
                matched = modes[i]
                break
            }
        }
        if (matched === "") {
            for (var j = 0; j < modes.length; j++) {
                if (modes[j].toUpperCase().indexOf(desiredMode.toUpperCase()) !== -1) {
                    matched = modes[j]
                    break
                }
            }
        }
        if (matched !== "") {
            activeVehicle.flightMode = matched
        } else {
            activeVehicle.flightMode = desiredMode
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
        anchors.margins: 10
        spacing: 8

        // Header
        Item {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 1.3

            RowLayout {
                anchors.fill: parent
                Text {
                    text: qsTr("FLIGHT CONTROL DECK")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                    font.bold: true
                    color: AeroQTheme.accentCyan
                    font.letterSpacing: 0.8
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.isConnected ? qsTr("LINK READY") : qsTr("NO LINK")
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: root.isConnected ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                }
            }
        }

        // =====================================================================
        // ARM / DISARM MASTER BUTTON
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 2.6
            radius: 3
            color: !root.isConnected ? Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.6)
                 : (root.isArmed ? Qt.rgba(1, 34 / 255, 68 / 255, 0.25) : Qt.rgba(0, 1, 102 / 255, 0.25))
            border.color: !root.isConnected ? AeroQTheme.borderDim
                        : (root.isArmed ? AeroQTheme.statusDisarmed : AeroQTheme.statusArmed)
            border.width: 1.5

            RowLayout {
                anchors.centerIn: parent
                spacing: 8

                Rectangle {
                    width: 10; height: 10; radius: 5
                    color: root.isArmed ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                }

                Text {
                    text: !root.isConnected ? qsTr("VEHICLE OFFLINE")
                        : (root.isArmed ? qsTr("DISARM VEHICLE") : qsTr("ARM VEHICLE"))
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.85
                    font.bold: true
                    color: !root.isConnected ? AeroQTheme.textMuted
                         : (root.isArmed ? AeroQTheme.statusDisarmed : AeroQTheme.statusArmed)
                    font.letterSpacing: 1.0
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.isConnected
                onClicked: {
                    if (root.isArmed) {
                        root.requestActionConfirmation(
                            qsTr("CONFIRM DISARM VEHICLE"),
                            qsTr("Are you sure you want to DISARM the vehicle?\nMotors will stop immediately. Ensure vehicle is grounded."),
                            AeroQTheme.statusDisarmed,
                            function() {
                                if (root.activeVehicle) root.activeVehicle.armed = false
                            }
                        )
                    } else {
                        root.requestActionConfirmation(
                            qsTr("CONFIRM ARM VEHICLE"),
                            qsTr("WARNING: Motors will be energized and start spinning.\nEnsure area is clear of personnel and obstacles before arming."),
                            AeroQTheme.statusArmed,
                            function() {
                                if (root.activeVehicle) root.activeVehicle.armed = true
                            }
                        )
                    }
                }
            }
        }

        // Horizontal Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: AeroQTheme.borderDim
        }

        // =====================================================================
        // GUIDED TAKEOFF CONTROL
        // =====================================================================
        Text {
            text: qsTr("GUIDED TAKEOFF ALTITUDE")
            font.family: AeroQTheme.fontFamilyHeader
            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
            font.bold: true
            color: AeroQTheme.textSecondary
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            // Stepper Minus
            Rectangle {
                width: ScreenTools.defaultFontPixelHeight * 2.0
                height: width
                radius: 2
                color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.7)
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "-"
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 1.1
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.takeoffAltitude = Math.max(2.0, root.takeoffAltitude - 1.0)
                }
            }

            // Altitude Readout Display
            Rectangle {
                Layout.fillWidth: true
                height: ScreenTools.defaultFontPixelHeight * 2.0
                radius: 2
                color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.9)
                border.color: AeroQTheme.accentCyan
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: root.takeoffAltitude.toFixed(1)
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.95
                        font.bold: true
                        color: AeroQTheme.accentCyan
                    }
                    Text {
                        text: "m AGL"
                        font.family: AeroQTheme.fontFamilyTelemetry
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                        color: AeroQTheme.textSecondary
                    }
                }
            }

            // Stepper Plus
            Rectangle {
                width: ScreenTools.defaultFontPixelHeight * 2.0
                height: width
                radius: 2
                color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.7)
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 1.1
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.takeoffAltitude = Math.min(120.0, root.takeoffAltitude + 1.0)
                }
            }
        }

        // Quick Altitude Preset Pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: [5, 10, 20, 50]
                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 1.3
                    radius: 2
                    color: root.takeoffAltitude === modelData ? Qt.rgba(0, 229 / 255, 1, 0.25) : Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.5)
                    border.color: root.takeoffAltitude === modelData ? AeroQTheme.accentCyan : AeroQTheme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: modelData + "m"
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                        font.bold: true
                        color: root.takeoffAltitude === modelData ? AeroQTheme.accentCyan : AeroQTheme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.takeoffAltitude = modelData
                    }
                }
            }
        }

        // EXECUTE TAKEOFF BUTTON
        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 2.2
            radius: 3
            color: !root.isConnected ? Qt.rgba(20 / 255, 20 / 255, 20 / 255, 0.6) : Qt.rgba(0, 229 / 255, 1, 0.15)
            border.color: !root.isConnected ? AeroQTheme.borderDim : AeroQTheme.accentCyan
            border.width: 1.2

            Text {
                anchors.centerIn: parent
                text: qsTr("▲ EXECUTE TAKEOFF (%1m)").arg(root.takeoffAltitude.toFixed(0))
                font.family: AeroQTheme.fontFamilyHeader
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                font.bold: true
                color: !root.isConnected ? AeroQTheme.textMuted : AeroQTheme.accentCyan
                font.letterSpacing: 0.8
            }

            MouseArea {
                anchors.fill: parent
                enabled: root.isConnected
                onClicked: {
                    root.requestActionConfirmation(
                        qsTr("CONFIRM GUIDED TAKEOFF"),
                        qsTr("Vehicle will arm (if disarmed) and climb to %1 meters.\nEnsure GPS 3D fix is verified.").arg(root.takeoffAltitude.toFixed(1)),
                        AeroQTheme.accentCyan,
                        function() {
                            if (root.activeVehicle) {
                                root.activeVehicle.guidedModeTakeoff(root.takeoffAltitude)
                            }
                        }
                    )
                }
            }
        }

        // Horizontal Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: AeroQTheme.borderDim
        }

        // =====================================================================
        // FLIGHT MODE BUTTONS (LOITER, ALT HOLD, STABILIZE, AUTO, RTL, LAND)
        // =====================================================================
        Text {
            text: qsTr("TACTICAL FLIGHT MODES")
            font.family: AeroQTheme.fontFamilyHeader
            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
            font.bold: true
            color: AeroQTheme.textSecondary
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 4
            columnSpacing: 4

            // Helper mode button component
            component ModeButton: Rectangle {
                property string modeName: ""
                property string modeLabel: ""
                property color btnColor: AeroQTheme.accentCyan
                readonly property bool isCurrent: root.curMode.toUpperCase().indexOf(modeName.toUpperCase()) !== -1

                Layout.fillWidth: true
                height: ScreenTools.defaultFontPixelHeight * 1.8
                radius: 2
                color: isCurrent ? Qt.rgba(0, 229 / 255, 1, 0.25) : Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.6)
                border.color: isCurrent ? btnColor : AeroQTheme.borderDim
                border.width: isCurrent ? 1.5 : 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Rectangle {
                        width: 5; height: 5; radius: 2.5
                        color: isCurrent ? btnColor : "transparent"
                    }
                    Text {
                        text: modeLabel
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                        font.bold: true
                        color: isCurrent ? btnColor : AeroQTheme.textPrimary
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: root.isConnected
                    onClicked: {
                        root.requestActionConfirmation(
                            qsTr("CONFIRM MODE CHANGE: %1").arg(modeLabel),
                            qsTr("Switch active flight mode to %1?").arg(modeLabel),
                            btnColor,
                            function() {
                                if (modeName === "RTL") {
                                    if (root.activeVehicle) root.activeVehicle.guidedModeRTL(false)
                                } else if (modeName === "LAND") {
                                    if (root.activeVehicle) root.activeVehicle.guidedModeLand()
                                } else {
                                    root.setVehicleFlightMode(modeName)
                                }
                            }
                        )
                    }
                }
            }

            ModeButton { modeName: "LOITER";    modeLabel: "LOITER";      btnColor: AeroQTheme.accentCyan }
            ModeButton { modeName: "ALT_HOLD";  modeLabel: "ALT HOLD";    btnColor: AeroQTheme.accentCyan }
            ModeButton { modeName: "STABILIZE"; modeLabel: "STABILIZE";   btnColor: AeroQTheme.statusWarning }
            ModeButton { modeName: "AUTO";      modeLabel: "AUTO MISSION";btnColor: AeroQTheme.accentCyan }
            ModeButton { modeName: "RTL";       modeLabel: "RTL";         btnColor: AeroQTheme.statusWarning }
            ModeButton { modeName: "LAND";      modeLabel: "LAND";        btnColor: AeroQTheme.statusDisarmed }
        }
    }

    // =========================================================================
    // SAFETY CONFIRMATION MODAL OVERLAY
    // =========================================================================
    Rectangle {
        id: confirmationModal
        anchors.fill: parent
        visible: root.confirmDialogOpen
        color: Qt.rgba(3 / 255, 6 / 255, 13 / 255, 0.94)
        border.color: root.confirmAccentColor
        border.width: 1.5
        radius: 4
        z: 99

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 24
            spacing: 10

            // Warning Icon & Title
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                Text {
                    text: "⚠"
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 1.2
                    color: root.confirmAccentColor
                }
                Text {
                    text: root.confirmTitle
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                    font.bold: true
                    color: root.confirmAccentColor
                }
            }

            // Description message
            Text {
                Layout.fillWidth: true
                text: root.confirmMessage
                font.family: AeroQTheme.fontFamilyTelemetry
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                color: AeroQTheme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            // Action Buttons
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 8

                // Abort / Cancel
                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 2.0
                    radius: 2
                    color: Qt.rgba(30 / 255, 40 / 255, 60 / 255, 0.8)
                    border.color: AeroQTheme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("ABORT")
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.70
                        font.bold: true
                        color: AeroQTheme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.cancelActionConfirmation()
                    }
                }

                // Confirm Execution
                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 2.0
                    radius: 2
                    color: Qt.rgba(root.confirmAccentColor.r, root.confirmAccentColor.g, root.confirmAccentColor.b, 0.3)
                    border.color: root.confirmAccentColor
                    border.width: 1.5

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("CONFIRM")
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.70
                        font.bold: true
                        color: root.confirmAccentColor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.executeConfirmedAction()
                    }
                }
            }
        }
    }
}

