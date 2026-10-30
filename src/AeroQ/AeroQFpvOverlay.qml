import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.ScreenTools

Item {
    id: root

    width: isMinimized ? (ScreenTools.defaultFontPixelWidth * 16) : Math.max(ScreenTools.defaultFontPixelWidth * 34, 280)
    height: isMinimized ? (ScreenTools.defaultFontPixelHeight * 2.2) : Math.max(ScreenTools.defaultFontPixelHeight * 20, 210)

    property bool isMinimized: false

    // -------------------------------------------------------------------------
    // Telemetry Inputs
    // -------------------------------------------------------------------------
    readonly property var activeVehicle:  QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool isConnected:   activeVehicle !== null && !activeVehicle.communicationLost

    readonly property real altitude:     (activeVehicle && activeVehicle.altitudeRelative && !isNaN(activeVehicle.altitudeRelative.value))
                                         ? activeVehicle.altitudeRelative.value : NaN
    readonly property real groundspeed:  (activeVehicle && activeVehicle.groundSpeed && !isNaN(activeVehicle.groundSpeed.value))
                                         ? activeVehicle.groundSpeed.value : NaN
    readonly property real heading:      (activeVehicle && activeVehicle.heading && !isNaN(activeVehicle.heading.value))
                                         ? activeVehicle.heading.value : NaN
    readonly property real pitch:        (activeVehicle && activeVehicle.pitch && !isNaN(activeVehicle.pitch.value))
                                         ? activeVehicle.pitch.value : 0
    readonly property real roll:         (activeVehicle && activeVehicle.roll && !isNaN(activeVehicle.roll.value))
                                         ? activeVehicle.roll.value : 0

    readonly property var primaryBattery: (activeVehicle && activeVehicle.batteries && activeVehicle.batteries.count > 0)
                                          ? activeVehicle.batteries.get(0) : null
    readonly property real batteryVoltage: primaryBattery && primaryBattery.voltage ? primaryBattery.voltage.value : NaN

    // Check if QGC has real video stream decoding
    readonly property bool hasRealVideo: (QGroundControl.videoManager && (QGroundControl.videoManager.decoding || QGroundControl.videoManager.isUvc))

    // Redraw simulated canvas when attitude changes
    onPitchChanged: if (!hasRealVideo && !isMinimized) simCamCanvas.requestPaint()
    onRollChanged:  if (!hasRealVideo && !isMinimized) simCamCanvas.requestPaint()

    // -------------------------------------------------------------------------
    // Background Frame & Drag Handle
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

    // -------------------------------------------------------------------------
    // Header Bar (Draggable)
    // -------------------------------------------------------------------------
    Item {
        id: titleBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: ScreenTools.defaultFontPixelHeight * 1.6

        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: root
            drag.axis: Drag.XAndYAxis
            drag.minimumX: 0
            drag.minimumY: 0
            drag.maximumX: root.parent ? root.parent.width - root.width : 1000
            drag.maximumY: root.parent ? root.parent.height - root.height : 1000
            cursorShape: Qt.SizeAllCursor
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            Text {
                text: "📹"
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
            }

            Text {
                text: qsTr("FPV TACTICAL CAM 01")
                font.family: AeroQTheme.fontFamilyHeader
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                font.bold: true
                color: AeroQTheme.accentCyan
                font.letterSpacing: 0.8
            }

            Rectangle {
                width: 6; height: 6; radius: 3
                color: root.hasRealVideo ? AeroQTheme.statusArmed : AeroQTheme.statusWarning
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    PropertyAnimation { from: 1.0; to: 0.3; duration: 800 }
                    PropertyAnimation { from: 0.3; to: 1.0; duration: 800 }
                }
            }

            Item { Layout.fillWidth: true }

            // Minimize / Restore Toggle Button
            Rectangle {
                width: ScreenTools.defaultFontPixelWidth * 4
                height: ScreenTools.defaultFontPixelHeight * 1.1
                radius: 2
                color: Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.7)
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.isMinimized ? "▲" : "▼"
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.isMinimized = !root.isMinimized
                }
            }
        }
    }

    // -------------------------------------------------------------------------
    // Main Viewport (Video Stream OR Simulated Aerial Camera)
    // -------------------------------------------------------------------------
    Item {
        id: viewportContainer
        anchors.top: titleBar.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        visible: !root.isMinimized
        clip: true

        // Real QGC Video Stream Loader
        Loader {
            id: videoStreamLoader
            anchors.fill: parent
            active: root.hasRealVideo
            visible: root.hasRealVideo
            sourceComponent: Component {
                FlightDisplayViewVideo {
                    anchors.fill: parent
                }
            }
        }

        // Simulated Aerial Camera Canvas (fallback when no video hardware stream)
        Canvas {
            id: simCamCanvas
            anchors.fill: parent
            visible: !root.hasRealVideo
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                var w = width
                var h = height
                var cx = w / 2
                var cy = h / 2

                // Dark tactical sensor backdrop with gradient
                var sensorGrad = ctx.createLinearGradient(0, 0, 0, h)
                sensorGrad.addColorStop(0, "#030c14")
                sensorGrad.addColorStop(0.5, "#061826")
                sensorGrad.addColorStop(1, "#02070c")
                ctx.fillStyle = sensorGrad
                ctx.fillRect(0, 0, w, h)

                // Simulated scanlines
                ctx.strokeStyle = Qt.rgba(0, 229 / 255, 1, 0.04)
                ctx.lineWidth = 1
                ctx.beginPath()
                for (var y = 0; y < h; y += 4) {
                    ctx.moveTo(0, y)
                    ctx.lineTo(w, y)
                }
                ctx.stroke()

                // Simulated wireframe terrain horizon
                ctx.save()
                ctx.translate(cx, cy)
                ctx.rotate(-root.roll * Math.PI / 180.0)
                var pitchPx = root.pitch * (h / 60.0)
                ctx.translate(0, pitchPx)

                // Artificial wireframe grid horizon
                ctx.strokeStyle = Qt.rgba(0, 229 / 255, 1, 0.25)
                ctx.lineWidth = 1.2
                ctx.beginPath()
                ctx.moveTo(-w, 0)
                ctx.lineTo(w, 0)
                ctx.stroke()

                // Perspective ground grid rays
                ctx.strokeStyle = Qt.rgba(0, 229 / 255, 1, 0.10)
                ctx.beginPath()
                for (var r = -w; r <= w; r += 40) {
                    ctx.moveTo(r, 0)
                    ctx.lineTo(r * 2.5, h)
                }
                ctx.stroke()
                ctx.restore()

                // Badge: Simulated sensor mode
                ctx.fillStyle = Qt.rgba(255 / 255, 153 / 255, 0, 0.85)
                ctx.font = "bold 8px monospace"
                ctx.textAlign = "center"
                ctx.fillText("SIMULATED FLIR / EO SENSOR", cx, 16)

                // Corner Brackets
                AeroQTheme.drawTacticalBracket(ctx, 2, 2, w - 4, h - 4, 8, AeroQTheme.accentCyan)
            }
        }

        // =====================================================================
        // TACTICAL HEADS-UP OSD OVERLAY
        // =====================================================================
        Item {
            id: osdOverlay
            anchors.fill: parent

            // Center Crosshair Reticle
            Canvas {
                id: reticleCanvas
                anchors.centerIn: parent
                width: 60; height: 60
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    var cx = width / 2
                    var cy = height / 2

                    ctx.strokeStyle = AeroQTheme.accentCyan
                    ctx.lineWidth = 1.2

                    // Crosshair tick marks
                    ctx.beginPath()
                    ctx.moveTo(cx - 24, cy); ctx.lineTo(cx - 8, cy)
                    ctx.moveTo(cx + 8, cy);  ctx.lineTo(cx + 24, cy)
                    ctx.moveTo(cx, cy - 24); ctx.lineTo(cx, cy - 8)
                    ctx.moveTo(cx, cy + 8);  ctx.lineTo(cx, cy + 24)
                    ctx.stroke()

                    // Center circle
                    ctx.beginPath()
                    ctx.arc(cx, cy, 4, 0, Math.PI * 2)
                    ctx.stroke()
                }
            }

            // OSD Telemetry Badges (Top & Bottom Corners)
            // Top Left: Altitude
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 6
                width: altOsdText.contentWidth + 10
                height: ScreenTools.defaultFontPixelHeight * 1.1
                radius: 2
                color: Qt.rgba(3 / 255, 6 / 255, 13 / 255, 0.7)
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    id: altOsdText
                    anchors.centerIn: parent
                    text: qsTr("ALT: ") + AeroQTheme.formatAltitude(root.altitude)
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }
            }

            // Top Right: Speed
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 6
                width: spdOsdText.contentWidth + 10
                height: ScreenTools.defaultFontPixelHeight * 1.1
                radius: 2
                color: Qt.rgba(3 / 255, 6 / 255, 13 / 255, 0.7)
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    id: spdOsdText
                    anchors.centerIn: parent
                    text: qsTr("SPD: ") + AeroQTheme.formatSpeed(root.groundspeed)
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }
            }

            // Bottom Left: Battery Voltage
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 6
                width: batOsdText.contentWidth + 10
                height: ScreenTools.defaultFontPixelHeight * 1.1
                radius: 2
                color: Qt.rgba(3 / 255, 6 / 255, 13 / 255, 0.7)
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    id: batOsdText
                    anchors.centerIn: parent
                    text: qsTr("BAT: ") + AeroQTheme.formatVoltage(root.batteryVoltage)
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: AeroQTheme.statusArmed
                }
            }

            // Bottom Right: Heading
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 6
                width: hdgOsdText.contentWidth + 10
                height: ScreenTools.defaultFontPixelHeight * 1.1
                radius: 2
                color: Qt.rgba(3 / 255, 6 / 255, 13 / 255, 0.7)
                border.color: AeroQTheme.borderDim
                border.width: 1

                Text {
                    id: hdgOsdText
                    anchors.centerIn: parent
                    text: qsTr("HDG: ") + AeroQTheme.formatHeading(root.heading)
                    font.family: AeroQTheme.fontFamilyMono
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                    font.bold: true
                    color: AeroQTheme.accentCyan
                }
            }
        }
    }
}

