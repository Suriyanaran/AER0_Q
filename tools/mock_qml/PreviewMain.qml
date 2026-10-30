import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtPositioning
import QtLocation

import AeroQ
import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root
    width: 1340
    height: 800

    property var activeVehicle: QGroundControl.multiVehicleManager ? QGroundControl.multiVehicleManager.activeVehicle : null
    property int mapTypeIdx: 0 // 0: Street, 1: Satellite, 4: Night/Transit
    property bool followDrone: true

    // -------------------------------------------------------------------------
    // REAL TACTICAL MAP LAYER (OpenStreetMap / Satellite / Night)
    // -------------------------------------------------------------------------
    Plugin {
        id: osmPlugin
        name: "osm"
        PluginParameter { name: "osm.useragent"; value: "Aero-Q-GCS/2.4 (Tactical-Avionics)" }
        PluginParameter { name: "osm.mapping.providersrepository.disabled"; value: "true" }
    }

    Map {
        id: flightMap
        anchors.fill: parent
        plugin: osmPlugin
        center: QtPositioning.coordinate(13.0827, 80.2707)
        zoomLevel: 15.5
        minimumZoomLevel: 3
        maximumZoomLevel: 19

        activeMapType: supportedMapTypes.length > mapTypeIdx ? supportedMapTypes[mapTypeIdx] : null

        // Auto-center on drone when followDrone is active
        Connections {
            target: activeVehicle ? activeVehicle : null
            function onCoordinateChanged() {
                if (root.followDrone && activeVehicle && activeVehicle.coordinate && activeVehicle.coordinate.isValid) {
                    flightMap.center = activeVehicle.coordinate
                }
                if (activeVehicle && activeVehicle.coordinate && activeVehicle.coordinate.isValid) {
                    trailLine.addCoordinate(activeVehicle.coordinate)
                }
            }
        }

        // Flight Path Trail
        MapPolyline {
            id: trailLine
            line.width: 3
            line.color: AeroQTheme.accentCyan
        }

        // Home Position Marker
        MapQuickItem {
            id: homeMarker
            coordinate: (activeVehicle && activeVehicle.homePosition && activeVehicle.homePosition.isValid)
                        ? activeVehicle.homePosition
                        : QtPositioning.coordinate(13.0827, 80.2707)
            anchorPoint.x: homeItem.width / 2
            anchorPoint.y: homeItem.height / 2

            sourceItem: Item {
                id: homeItem
                width: 36
                height: 36

                Rectangle {
                    anchors.centerIn: parent
                    width: 28; height: 28; radius: 4
                    color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.85)
                    border.color: AeroQTheme.statusWarning
                    border.width: 2

                    Text {
                        anchors.centerIn: parent
                        text: "H"
                        font.pixelSize: 13
                        font.bold: true
                        color: AeroQTheme.statusWarning
                    }
                }
            }
        }

        // Live Drone Position & Heading Marker
        MapQuickItem {
            id: droneMarker
            coordinate: (activeVehicle && activeVehicle.coordinate && activeVehicle.coordinate.isValid)
                        ? activeVehicle.coordinate
                        : QtPositioning.coordinate(13.0827, 80.2707)
            anchorPoint.x: droneGlyph.width / 2
            anchorPoint.y: droneGlyph.height / 2

            sourceItem: Item {
                id: droneGlyph
                width: 70
                height: 70

                // Radar ping ring
                Rectangle {
                    anchors.centerIn: parent
                    width: 50; height: 50; radius: 25
                    color: "transparent"
                    border.color: AeroQTheme.accentCyan
                    border.width: 1.5

                    SequentialAnimation on scale {
                        running: true; loops: Animation.Infinite
                        PropertyAnimation { from: 0.8; to: 1.35; duration: 1200; easing.type: Easing.OutQuad }
                        PropertyAnimation { from: 1.35; to: 0.8; duration: 1200; easing.type: Easing.InQuad }
                    }
                    SequentialAnimation on opacity {
                        running: true; loops: Animation.Infinite
                        PropertyAnimation { from: 0.9; to: 0.2; duration: 1200 }
                        PropertyAnimation { from: 0.2; to: 0.9; duration: 1200 }
                    }
                }

                // Rotating Drone Shape & Heading Arrow
                Item {
                    anchors.centerIn: parent
                    width: 40; height: 40
                    rotation: activeVehicle ? (activeVehicle.heading ? activeVehicle.heading.value : 0) : 0

                    Canvas {
                        anchors.fill: parent
                        onPaint: {
                            var ctx = getContext("2d")
                            ctx.reset()
                            var cx = width / 2
                            var cy = height / 2

                            // Heading Direction Arrow
                            ctx.fillStyle = "#00e5ff"
                            ctx.beginPath()
                            ctx.moveTo(cx, 2)
                            ctx.lineTo(cx + 8, 14)
                            ctx.lineTo(cx - 8, 14)
                            ctx.closePath()
                            ctx.fill()

                            // Center Drone Hub
                            ctx.fillStyle = "#00ff66"
                            ctx.beginPath()
                            ctx.arc(cx, cy, 5, 0, Math.PI * 2)
                            ctx.fill()

                            // Quad arms
                            ctx.strokeStyle = "#00e5ff"
                            ctx.lineWidth = 2
                            ctx.beginPath()
                            ctx.moveTo(cx - 12, cy - 12); ctx.lineTo(cx + 12, cy + 12)
                            ctx.moveTo(cx - 12, cy + 12); ctx.lineTo(cx + 12, cy - 12)
                            ctx.stroke()

                            // Rotor circles
                            ctx.strokeStyle = "rgba(0, 229, 255, 0.7)"
                            ctx.lineWidth = 1.2
                            var rotors = [
                                [cx - 12, cy - 12],
                                [cx + 12, cy - 12],
                                [cx - 12, cy + 12],
                                [cx + 12, cy + 12]
                            ]
                            for (var i = 0; i < rotors.length; i++) {
                                ctx.beginPath()
                                ctx.arc(rotors[i][0], rotors[i][1], 5, 0, Math.PI * 2)
                                ctx.stroke()
                            }
                        }
                    }
                }

                // Callsign Tag
                Rectangle {
                    anchors.top: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.topMargin: -12
                    width: callsignText.implicitWidth + 8
                    height: 16
                    radius: 2
                    color: Qt.rgba(3 / 255, 6 / 255, 13 / 255, 0.85)
                    border.color: AeroQTheme.borderDim
                    border.width: 1

                    Text {
                        id: callsignText
                        anchors.centerIn: parent
                        text: "AERO-1 • " + (activeVehicle && activeVehicle.altitudeRelative ? activeVehicle.altitudeRelative.valueString : "24.8") + "m"
                        font.pixelSize: 9
                        font.bold: true
                        color: AeroQTheme.accentCyan
                    }
                }
            }
        }

        // Map Drag & Pan Handling
        MouseArea {
            anchors.fill: parent
            property real lastX: 0
            property real lastY: 0
            property bool isDragging: false

            onPressed: (mouse) => {
                lastX = mouse.x
                lastY = mouse.y
                isDragging = true
            }
            onPositionChanged: (mouse) => {
                if (isDragging && (mouse.buttons & Qt.LeftButton)) {
                    var dx = lastX - mouse.x
                    var dy = lastY - mouse.y
                    flightMap.pan(dx, dy)
                    lastX = mouse.x
                    lastY = mouse.y
                    root.followDrone = false // Break follow mode while manual panning
                }
            }
            onReleased: {
                isDragging = false
            }
            onWheel: (wheel) => {
                if (wheel.angleDelta.y > 0) {
                    flightMap.zoomLevel = Math.min(flightMap.maximumZoomLevel, flightMap.zoomLevel + 0.5)
                } else if (wheel.angleDelta.y < 0) {
                    flightMap.zoomLevel = Math.max(flightMap.minimumZoomLevel, flightMap.zoomLevel - 0.5)
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // TACTICAL MAP VIGNETTE & MILITARY GRID OVERLAY
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        enabled: false

        // Center Tactical Boresight Crosshair
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                var cx = width / 2
                var cy = height / 2

                ctx.strokeStyle = "rgba(0, 229, 255, 0.15)"
                ctx.lineWidth = 1

                // Subtle range ring around center
                ctx.beginPath()
                ctx.arc(cx, cy, 140, 0, Math.PI * 2)
                ctx.arc(cx, cy, 260, 0, Math.PI * 2)
                ctx.stroke()

                // Small center cross
                ctx.strokeStyle = "rgba(0, 229, 255, 0.3)"
                ctx.beginPath()
                ctx.moveTo(cx - 20, cy); ctx.lineTo(cx - 6, cy)
                ctx.moveTo(cx + 6, cy); ctx.lineTo(cx + 20, cy)
                ctx.moveTo(cx, cy - 20); ctx.lineTo(cx, cy - 6)
                ctx.moveTo(cx, cy + 6); ctx.lineTo(cx, cy + 20)
                ctx.stroke()
            }
        }
    }

    // -------------------------------------------------------------------------
    // FLOATING TACTICAL MAP CONTROLS
    // Placed in bottom-center above event console
    // -------------------------------------------------------------------------
    Rectangle {
        id: mapToolbar
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 190
        anchors.horizontalCenter: parent.horizontalCenter
        width: toolbarRow.implicitWidth + 24
        height: 38
        radius: 4
        z: 8
        color: Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.88)
        border.color: AeroQTheme.borderDim
        border.width: 1

        RowLayout {
            id: toolbarRow
            anchors.centerIn: parent
            spacing: 8

            // Zoom In
            Rectangle {
                width: 30; height: 28; radius: 3
                color: zoomInMouse.containsMouse ? Qt.rgba(0, 229 / 255, 1, 0.25) : "transparent"
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "+"
                    font.pixelSize: 18
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }
                MouseArea {
                    id: zoomInMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: flightMap.zoomLevel = Math.min(flightMap.maximumZoomLevel, flightMap.zoomLevel + 1)
                }
            }

            // Zoom Out
            Rectangle {
                width: 30; height: 28; radius: 3
                color: zoomOutMouse.containsMouse ? Qt.rgba(0, 229 / 255, 1, 0.25) : "transparent"
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "-"
                    font.pixelSize: 18
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }
                MouseArea {
                    id: zoomOutMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: flightMap.zoomLevel = Math.max(flightMap.minimumZoomLevel, flightMap.zoomLevel - 1)
                }
            }

            // Recenter / Track Drone
            Rectangle {
                height: 28; width: recenterText.implicitWidth + 16; radius: 3
                color: root.followDrone ? Qt.rgba(0, 229 / 255, 1, 0.3) : (recenterMouse.containsMouse ? Qt.rgba(0, 229 / 255, 1, 0.15) : "transparent")
                border.color: root.followDrone ? AeroQTheme.accentCyan : AeroQTheme.borderDim
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "🎯"
                        font.pixelSize: 12
                    }
                    Text {
                        id: recenterText
                        text: root.followDrone ? "TRACKING" : "RECENTER"
                        font.pixelSize: 10
                        font.bold: true
                        color: root.followDrone ? AeroQTheme.accentCyan : AeroQTheme.textDim
                    }
                }
                MouseArea {
                    id: recenterMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.followDrone = true
                        if (activeVehicle && activeVehicle.coordinate && activeVehicle.coordinate.isValid) {
                            flightMap.center = activeVehicle.coordinate
                        }
                    }
                }
            }

            // Map Style Switcher (Street / Satellite / Night)
            Rectangle {
                height: 28; width: styleText.implicitWidth + 18; radius: 3
                color: styleMouse.containsMouse ? Qt.rgba(0, 229 / 255, 1, 0.2) : "transparent"
                border.color: AeroQTheme.borderDim
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "🗺️"
                        font.pixelSize: 11
                    }
                    Text {
                        id: styleText
                        property var styleNames: ["STREET", "SATELLITE", "NIGHT / TRANSIT"]
                        property var styleIndices: [0, 1, 4]
                        property int currentStyleStep: 0

                        text: styleNames[currentStyleStep]
                        font.pixelSize: 10
                        font.bold: true
                        color: AeroQTheme.accentCyan
                    }
                }
                MouseArea {
                    id: styleMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        styleText.currentStyleStep = (styleText.currentStyleStep + 1) % styleText.styleNames.length
                        root.mapTypeIdx = styleText.styleIndices[styleText.currentStyleStep]
                    }
                }
            }

            // GPS Coordinates Readout
            Text {
                text: {
                    var lat = activeVehicle && activeVehicle.coordinate ? activeVehicle.coordinate.latitude : 13.0827
                    var lon = activeVehicle && activeVehicle.coordinate ? activeVehicle.coordinate.longitude : 80.2707
                    return lat.toFixed(5) + "°N, " + lon.toFixed(5) + "°E | Z: " + flightMap.zoomLevel.toFixed(1)
                }
                font.pixelSize: 10
                font.family: "Consolas"
                color: AeroQTheme.textDim
            }
        }
    }

    // -------------------------------------------------------------------------
    // AERO-Q TACTICAL MASTER HUD (Additive Overlay)
    // -------------------------------------------------------------------------
    AeroQHud {
        id: hudOverlay
        anchors.fill: parent
        z: 10
    }
}
