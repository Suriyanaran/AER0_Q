import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    width:  Math.max(ScreenTools.defaultFontPixelWidth * 34, 300)
    height: Math.max(ScreenTools.defaultFontPixelHeight * 24, 300)

    // Feature flag: simulation mode only
    property bool enableFleetSimulation: true

    // Confirmation dialog state for operator safety
    property bool confirmDialogOpen: false
    property string pendingSosId: ""
    property string pendingAction: ""

    // -------------------------------------------------------------------------
    // SOS Queue Mock Model
    // -------------------------------------------------------------------------
    ListModel {
        id: sosModel

        ListElement {
            sosId: "#SOS-8092"
            requesterName: "Dr. Elena Rostova"
            phone: "+1 (555) 019-4823"
            emergencyType: "SAR / AVALANCHE SEARCH"
            coords: "47.3769° N, 8.5417° E"
            primaryDrone: "AERO-01 Alpha"
            backupDrone: "AERO-03 Charlie"
            status: "PENDING OPERATOR"
        }
        ListElement {
            sosId: "#SOS-8093"
            requesterName: "Marcus Vance"
            phone: "+1 (555) 014-9912"
            emergencyType: "MEDICAL / DEFIB EVAC"
            coords: "47.3821° N, 8.5302° E"
            primaryDrone: "AERO-02 Bravo"
            backupDrone: "AERO-04 Delta"
            status: "PENDING OPERATOR"
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
            color: AeroQTheme.statusWarning
            opacity: 0.90
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
                    text: qsTr("EMERGENCY SOS QUEUE")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                    font.bold: true
                    color: AeroQTheme.statusWarning
                    font.letterSpacing: 0.8
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: queueBadgeText.contentWidth + 10
                    height: ScreenTools.defaultFontPixelHeight * 0.95
                    radius: 2
                    color: Qt.rgba(1, 34 / 255, 68 / 255, 0.20)
                    border.color: AeroQTheme.statusDisarmed
                    border.width: 1
                    Text {
                        id: queueBadgeText
                        anchors.centerIn: parent
                        text: qsTr("%1 ACTIVE").arg(sosModel.count)
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.50
                        font.bold: true
                        color: AeroQTheme.statusDisarmed
                    }
                }
            }
        }

        // Safety Warning Banner
        Rectangle {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 1.5
            radius: 2
            color: Qt.rgba(1, 153 / 255, 0, 0.12)
            border.color: AeroQTheme.statusWarning
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 6
                Text { text: "⚠"; color: AeroQTheme.statusWarning; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.8 }
                Text {
                    text: qsTr("MANDATORY OPERATOR APPROVAL • NO AUTO-LAUNCH")
                    font.family: AeroQTheme.fontFamilyTelemetry
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.58
                    font.bold: true
                    color: AeroQTheme.statusWarning
                }
            }
        }

        // SOS Cards List
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.enableFleetSimulation ? sosModel : 0
            spacing: 6
            clip: true

            delegate: Rectangle {
                width: parent.width
                height: ScreenTools.defaultFontPixelHeight * 7.5
                radius: 2
                color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.70)
                border.color: model.status === "APPROVED" ? AeroQTheme.statusArmed
                            : (model.status === "REJECTED" ? AeroQTheme.borderDim : AeroQTheme.statusWarning)
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 3

                    // Row 1: SOS ID & Type
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: model.sosId + " • " + model.emergencyType
                            font.family: AeroQTheme.fontFamilyHeader
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.62
                            font.bold: true
                            color: AeroQTheme.statusWarning
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: model.status
                            font.family: AeroQTheme.fontFamilyMono
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.50
                            font.bold: true
                            color: model.status === "APPROVED" ? AeroQTheme.statusArmed
                                 : (model.status === "REJECTED" ? AeroQTheme.textMuted : AeroQTheme.accentCyan)
                        }
                    }

                    // Row 2: Requester & Phone
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "👤 " + model.requesterName + " (" + model.phone + ")"
                            font.family: AeroQTheme.fontFamilyTelemetry
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.58
                            color: AeroQTheme.textPrimary
                        }
                    }

                    // Row 3: Coords
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "📍 " + model.coords
                            font.family: AeroQTheme.fontFamilyMono
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                            color: AeroQTheme.accentCyan
                        }
                    }

                    // Row 4: Assigned Assets
                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "🚁 PRI: " + model.primaryDrone + " | BCK: " + model.backupDrone
                            font.family: AeroQTheme.fontFamilyMono
                            font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                            color: AeroQTheme.textSecondary
                        }
                    }

                    // Row 5: Action Buttons (Approve / Reject)
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        visible: model.status === "PENDING OPERATOR"

                        Rectangle {
                            Layout.fillWidth: true
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            radius: 2
                            color: Qt.rgba(0, 1, 102 / 255, 0.2)
                            border.color: AeroQTheme.statusArmed
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: qsTr("APPROVE")
                                font.family: AeroQTheme.fontFamilyHeader
                                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.58
                                font.bold: true
                                color: AeroQTheme.statusArmed
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    root.pendingSosId = model.sosId
                                    root.pendingAction = "APPROVE"
                                    root.confirmDialogOpen = true
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            height: ScreenTools.defaultFontPixelHeight * 1.5
                            radius: 2
                            color: Qt.rgba(1, 34 / 255, 68 / 255, 0.2)
                            border.color: AeroQTheme.statusDisarmed
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: qsTr("REJECT")
                                font.family: AeroQTheme.fontFamilyHeader
                                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.58
                                font.bold: true
                                color: AeroQTheme.statusDisarmed
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    model.status = "REJECTED"
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Confirmation Modal for SOS Operator Approval
    Rectangle {
        anchors.fill: parent
        visible: root.confirmDialogOpen
        color: Qt.rgba(3 / 255, 6 / 255, 13 / 255, 0.95)
        border.color: AeroQTheme.statusWarning
        border.width: 1.5
        radius: 4
        z: 99

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 20
            spacing: 8

            Text {
                text: qsTr("CONFIRM SOS DISPATCH")
                font.family: AeroQTheme.fontFamilyHeader
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.75
                font.bold: true
                color: AeroQTheme.statusWarning
                Layout.alignment: Qt.AlignHCenter
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Authorize operator dispatch for %1?\n(Asset will be queued for manual pilot execution)").arg(root.pendingSosId)
                font.family: AeroQTheme.fontFamilyTelemetry
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                color: AeroQTheme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 1.8
                    radius: 2
                    color: Qt.rgba(30 / 255, 40 / 255, 60 / 255, 0.8)
                    border.color: AeroQTheme.borderDim
                    border.width: 1
                    Text { anchors.centerIn: parent; text: qsTr("CANCEL"); color: AeroQTheme.textSecondary; font.family: AeroQTheme.fontFamilyHeader; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.confirmDialogOpen = false
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 1.8
                    radius: 2
                    color: Qt.rgba(0, 1, 102 / 255, 0.3)
                    border.color: AeroQTheme.statusArmed
                    border.width: 1.5
                    Text { anchors.centerIn: parent; text: qsTr("AUTHORIZE"); color: AeroQTheme.statusArmed; font.family: AeroQTheme.fontFamilyHeader; font.bold: true }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            for (var i = 0; i < sosModel.count; i++) {
                                if (sosModel.get(i).sosId === root.pendingSosId) {
                                    sosModel.setProperty(i, "status", "APPROVED")
                                    break
                                }
                            }
                            root.confirmDialogOpen = false
                        }
                    }
                }
            }
        }
    }
}

