import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root
    anchors.fill: parent

    // Injected properties from FlyView
    property var occluders
    property var mapControl

    // -------------------------------------------------------------------------
    // Persistent Settings
    // -------------------------------------------------------------------------
    Settings {
        id: aeroSettings
        category: "AeroQ"

        property bool enableTacticalHud:      true
        property bool enableFleetSimulation:  true
        property bool showFpvOverlay:         true
        property real hudOpacity:             0.95
    }

    // Settings Toggle Master Visibility
    visible: aeroSettings.enableTacticalHud
    opacity: aeroSettings.hudOpacity

    // -------------------------------------------------------------------------
    // Occluders (Reporting covered areas so map vehicle tracking avoids them)
    // -------------------------------------------------------------------------
    property var customOccluders: (!visible) ? [] : [
        topBar.visible ? Qt.rect(topBar.x, topBar.y, topBar.width, topBar.height) : Qt.rect(0, 0, 0, 0),
        pfdPanel.visible ? Qt.rect(pfdPanel.x, pfdPanel.y, pfdPanel.width, pfdPanel.height) : Qt.rect(0, 0, 0, 0),
        rightColumn.visible ? Qt.rect(rightColumn.x, rightColumn.y, rightColumn.width, rightColumn.height) : Qt.rect(0, 0, 0, 0),
        bottomConsole.visible ? Qt.rect(bottomConsole.x, bottomConsole.y, bottomConsole.width, bottomConsole.height) : Qt.rect(0, 0, 0, 0)
    ]

    // Panel visibility states for operator flexibility
    property bool showPfd:            true
    property bool showRightColumn:    true
    property bool showBottomConsole:  true
    property bool showFlightControls: false
    property bool showFleetPanel:     false
    property bool showSosPanel:       false

    // -------------------------------------------------------------------------
    // 1. TOP HUD STATUS BAR
    // -------------------------------------------------------------------------
    AeroQTopBar {
        id: topBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        z: 10

        onToggleFlightControls: root.showFlightControls = !root.showFlightControls
        onToggleFleetPanel:     root.showFleetPanel = !root.showFleetPanel
        onToggleSosPanel:       root.showSosPanel = !root.showSosPanel
    }

    // -------------------------------------------------------------------------
    // 2. LEFT PANEL: Tactical PFD / EFIS & Quick Drawer Bar
    // -------------------------------------------------------------------------
    Item {
        id: leftArea
        anchors.top: topBar.bottom
        anchors.bottom: bottomConsole.top
        anchors.left: parent.left
        anchors.margins: ScreenTools.defaultFontPixelWidth * 0.75
        // Position clear of QGC's left toolstrip if occluders is available
        anchors.leftMargin: (occluders && occluders.toolStrip && occluders.toolStrip.width > 0)
                            ? (occluders.toolStrip.x + occluders.toolStrip.width + ScreenTools.defaultFontPixelWidth * 0.75)
                            : (ScreenTools.defaultFontPixelWidth * 0.75)
        width: pfdPanel.width
        z: 5

        ColumnLayout {
            anchors.fill: parent
            spacing: 6

            // Tactical Action Buttons Strip
            RowLayout {
                spacing: 4
                Layout.fillWidth: true

                // Toggle PFD
                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 1.5
                    radius: 2
                    color: root.showPfd ? Qt.rgba(0, 229 / 255, 1, 0.25) : Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.8)
                    border.color: root.showPfd ? AeroQTheme.accentCyan : AeroQTheme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("PFD")
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                        font.bold: true
                        color: root.showPfd ? AeroQTheme.accentCyan : AeroQTheme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.showPfd = !root.showPfd
                    }
                }

                // Flight Controls Toggle
                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 1.5
                    radius: 2
                    color: root.showFlightControls ? Qt.rgba(0, 229 / 255, 1, 0.25) : Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.8)
                    border.color: root.showFlightControls ? AeroQTheme.accentCyan : AeroQTheme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("FLIGHT CTRL")
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                        font.bold: true
                        color: root.showFlightControls ? AeroQTheme.accentCyan : AeroQTheme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.showFlightControls = !root.showFlightControls
                            if (root.showFlightControls) {
                                root.showFleetPanel = false
                                root.showSosPanel = false
                            }
                        }
                    }
                }

                // Fleet Overwatch Toggle
                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 1.5
                    radius: 2
                    color: root.showFleetPanel ? Qt.rgba(0, 229 / 255, 1, 0.25) : Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.8)
                    border.color: root.showFleetPanel ? AeroQTheme.accentCyan : AeroQTheme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("FLEET")
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                        font.bold: true
                        color: root.showFleetPanel ? AeroQTheme.accentCyan : AeroQTheme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.showFleetPanel = !root.showFleetPanel
                            if (root.showFleetPanel) {
                                root.showFlightControls = false
                                root.showSosPanel = false
                            }
                        }
                    }
                }

                // SOS Queue Toggle
                Rectangle {
                    Layout.fillWidth: true
                    height: ScreenTools.defaultFontPixelHeight * 1.5
                    radius: 2
                    color: root.showSosPanel ? Qt.rgba(255 / 255, 153 / 255, 0, 0.25) : Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.8)
                    border.color: root.showSosPanel ? AeroQTheme.statusWarning : AeroQTheme.borderDim
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: qsTr("SOS")
                        font.family: AeroQTheme.fontFamilyHeader
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.60
                        font.bold: true
                        color: root.showSosPanel ? AeroQTheme.statusWarning : AeroQTheme.textSecondary
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.showSosPanel = !root.showSosPanel
                            if (root.showSosPanel) {
                                root.showFlightControls = false
                                root.showFleetPanel = false
                            }
                        }
                    }
                }
            }

            // PFD Component
            AeroQPfd {
                id: pfdPanel
                visible: root.showPfd
            }

            Item { Layout.fillHeight: true }
        }
    }

    // -------------------------------------------------------------------------
    // 3. RIGHT COLUMN: Health Matrix, Motors, Rolling Chart, & Link Deck
    // -------------------------------------------------------------------------
    Item {
        id: rightColumn
        anchors.top: topBar.bottom
        anchors.bottom: bottomConsole.top
        anchors.right: parent.right
        anchors.margins: ScreenTools.defaultFontPixelWidth * 0.75
        width: healthPanel.width
        visible: root.showRightColumn
        z: 5

        Flickable {
            anchors.fill: parent
            contentWidth: rightLayout.width
            contentHeight: rightLayout.height
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: rightLayout
                width: rightColumn.width
                spacing: 6

                // Section 1: Avionics Health Matrix & Motors
                AeroQHealthPanel {
                    id: healthPanel
                    Layout.fillWidth: true
                }

                // Section 2: Real-Time Rolling Telemetry Chart
                AeroQTelemetryChart {
                    Layout.fillWidth: true
                }

                // Section 3: MAVLink Connection Deck
                AeroQConnectionDeck {
                    Layout.fillWidth: true
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // 4. FLOATING DRAWERS: Flight Controls / Fleet / SOS
    // -------------------------------------------------------------------------
    // Flight Controls Drawer
    AeroQFlightControls {
        id: flightControlsDrawer
        anchors.top: leftArea.top
        anchors.left: leftArea.right
        anchors.leftMargin: 8
        visible: root.showFlightControls
        z: 20
    }

    // Fleet Panel Drawer
    AeroQFleetPanel {
        id: fleetDrawer
        anchors.top: leftArea.top
        anchors.left: leftArea.right
        anchors.leftMargin: 8
        visible: root.showFleetPanel
        enableFleetSimulation: aeroSettings.enableFleetSimulation
        z: 20
    }

    // SOS Panel Drawer
    AeroQSosPanel {
        id: sosDrawer
        anchors.top: leftArea.top
        anchors.left: leftArea.right
        anchors.leftMargin: 8
        visible: root.showSosPanel
        enableFleetSimulation: aeroSettings.enableFleetSimulation
        z: 20
    }

    // -------------------------------------------------------------------------
    // 5. PICTURE-IN-PICTURE FLOATING FPV WINDOW
    // -------------------------------------------------------------------------
    AeroQFpvOverlay {
        id: fpvPip
        visible: aeroSettings.showFpvOverlay
        x: (parent.width - width) / 2
        y: topBar.height + 16
        z: 15
    }

    // -------------------------------------------------------------------------
    // 6. BOTTOM PANEL: Tactical MAVLink & Event Console
    // -------------------------------------------------------------------------
    AeroQEventConsole {
        id: bottomConsole
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: ScreenTools.defaultFontPixelWidth * 0.75
        visible: root.showBottomConsole
        z: 10
    }
}

