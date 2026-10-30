import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    width:  Math.max(ScreenTools.defaultFontPixelWidth * 30, 260)
    height: Math.max(ScreenTools.defaultFontPixelHeight * 14, 180)

    // -------------------------------------------------------------------------
    // Telemetry Inputs
    // -------------------------------------------------------------------------
    readonly property var activeVehicle:  QGroundControl.multiVehicleManager.activeVehicle
    readonly property bool isConnected:   activeVehicle !== null && !activeVehicle.communicationLost

    readonly property real altitude:     (activeVehicle && activeVehicle.altitudeRelative && !isNaN(activeVehicle.altitudeRelative.value))
                                         ? activeVehicle.altitudeRelative.value : NaN
    readonly property real groundspeed:  (activeVehicle && activeVehicle.groundSpeed && !isNaN(activeVehicle.groundSpeed.value))
                                         ? activeVehicle.groundSpeed.value : NaN

    // Data buffer for rolling history (last 50 points)
    property var _historyData: []
    readonly property int maxPoints: 50

    // Sampling timer (every 1 second)
    Timer {
        id: sampleTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            var curAlt = isNaN(root.altitude) ? null : root.altitude
            var curSpd = isNaN(root.groundspeed) ? null : root.groundspeed

            var newHist = root._historyData.slice(0)
            newHist.push({ alt: curAlt, spd: curSpd })
            if (newHist.length > root.maxPoints) {
                newHist.shift()
            }
            root._historyData = newHist
            chartCanvas.requestPaint()
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
        spacing: 4

        // ---------------------------------------------------------------------
        // Header & Legend Bar
        // ---------------------------------------------------------------------
        Item {
            Layout.fillWidth: true
            height: ScreenTools.defaultFontPixelHeight * 1.3

            RowLayout {
                anchors.fill: parent
                spacing: 6

                Text {
                    text: qsTr("TELEMETRY CHART")
                    font.family: AeroQTheme.fontFamilyHeader
                    font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                    font.bold: true
                    color: AeroQTheme.accentCyan
                    font.letterSpacing: 0.8
                }

                Item { Layout.fillWidth: true }

                // Altitude Legend
                RowLayout {
                    spacing: 3
                    Rectangle { width: 8; height: 3; color: AeroQTheme.accentCyan }
                    Text {
                        text: qsTr("ALT: ") + AeroQTheme.formatAltitude(root.altitude)
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                        font.bold: true
                        color: AeroQTheme.accentCyan
                    }
                }

                // Speed Legend
                RowLayout {
                    spacing: 3
                    Rectangle { width: 8; height: 3; color: AeroQTheme.statusWarning }
                    Text {
                        text: qsTr("SPD: ") + AeroQTheme.formatSpeed(root.groundspeed)
                        font.family: AeroQTheme.fontFamilyMono
                        font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                        font.bold: true
                        color: AeroQTheme.statusWarning
                    }
                }
            }
        }

        // ---------------------------------------------------------------------
        // Canvas Plot Area
        // ---------------------------------------------------------------------
        Canvas {
            id: chartCanvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            renderTarget: Canvas.FramebufferObject

            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()

                var w = width
                var h = height

                if (w <= 0 || h <= 0) return

                // Dark grid backdrop
                ctx.fillStyle = Qt.rgba(4 / 255, 8 / 255, 16 / 255, 0.7)
                ctx.fillRect(0, 0, w, h)
                ctx.strokeStyle = AeroQTheme.borderDim
                ctx.lineWidth = 1
                ctx.strokeRect(0, 0, w, h)

                // Draw Horizontal Grid Lines
                ctx.strokeStyle = Qt.rgba(31 / 255, 64 / 255, 104 / 255, 0.3)
                ctx.lineWidth = 1
                ctx.beginPath()
                for (var g = 1; g < 4; g++) {
                    var gy = (h / 4) * g
                    ctx.moveTo(0, gy)
                    ctx.lineTo(w, gy)
                }
                ctx.stroke()

                // If no history data yet, show waiting note
                if (root._historyData.length < 2) {
                    ctx.font = "9px monospace"
                    ctx.fillStyle = AeroQTheme.textMuted
                    ctx.textAlign = "center"
                    ctx.textBaseline = "middle"
                    ctx.fillText("COLLECTING REAL-TIME SAMPLES...", w / 2, h / 2)
                    return
                }

                // Determine dynamic min/max bounds for Alt and Spd
                var maxAlt = 20.0
                var minAlt = 0.0
                var maxSpd = 15.0
                var minSpd = 0.0

                for (var i = 0; i < root._historyData.length; i++) {
                    var pt = root._historyData[i]
                    if (pt.alt !== null) {
                        if (pt.alt > maxAlt) maxAlt = pt.alt + 5
                        if (pt.alt < minAlt) minAlt = Math.min(0, pt.alt - 2)
                    }
                    if (pt.spd !== null) {
                        if (pt.spd > maxSpd) maxSpd = pt.spd + 5
                    }
                }

                var dx = w / (root.maxPoints - 1)
                var startIdx = root.maxPoints - root._historyData.length

                // =============================================================
                // Draw Altitude Trace (Cyan with Area Fill)
                // =============================================================
                ctx.save()
                ctx.beginPath()
                var firstAlt = true
                for (var j = 0; j < root._historyData.length; j++) {
                    var pAlt = root._historyData[j].alt
                    if (pAlt === null) continue
                    var xPos = (startIdx + j) * dx
                    var yAltNorm = (pAlt - minAlt) / Math.max(1, (maxAlt - minAlt))
                    var yPos = h - (yAltNorm * (h - 8)) - 4

                    if (firstAlt) {
                        ctx.moveTo(xPos, yPos)
                        firstAlt = false
                    } else {
                        ctx.lineTo(xPos, yPos)
                    }
                }

                if (!firstAlt) {
                    // Line stroke
                    ctx.strokeStyle = AeroQTheme.accentCyan
                    ctx.lineWidth = 1.6
                    ctx.stroke()

                    // Semi-transparent area fill underneath
                    var lastX = (startIdx + root._historyData.length - 1) * dx
                    var firstX = startIdx * dx
                    ctx.lineTo(lastX, h)
                    ctx.lineTo(firstX, h)
                    ctx.closePath()
                    var areaGrad = ctx.createLinearGradient(0, 0, 0, h)
                    areaGrad.addColorStop(0, Qt.rgba(0, 229 / 255, 1, 0.20))
                    areaGrad.addColorStop(1, Qt.rgba(0, 229 / 255, 1, 0.02))
                    ctx.fillStyle = areaGrad
                    ctx.fill()
                }
                ctx.restore()

                // =============================================================
                // Draw Ground Speed Trace (Neon Orange Line)
                // =============================================================
                ctx.save()
                ctx.beginPath()
                var firstSpd = true
                for (var k = 0; k < root._historyData.length; k++) {
                    var pSpd = root._historyData[k].spd
                    if (pSpd === null) continue
                    var spdXPos = (startIdx + k) * dx
                    var ySpdNorm = (pSpd - minSpd) / Math.max(1, (maxSpd - minSpd))
                    var spdYPos = h - (ySpdNorm * (h - 8)) - 4

                    if (firstSpd) {
                        ctx.moveTo(spdXPos, spdYPos)
                        firstSpd = false
                    } else {
                        ctx.lineTo(spdXPos, spdYPos)
                    }
                }

                if (!firstSpd) {
                    ctx.strokeStyle = AeroQTheme.statusWarning
                    ctx.lineWidth = 1.4
                    ctx.stroke()
                }
                ctx.restore()

                // Corner brackets
                AeroQTheme.drawTacticalBracket(ctx, 1, 1, w - 2, h - 2, 6, AeroQTheme.accentCyan)
            }
        }
    }
}

