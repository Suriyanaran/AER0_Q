import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import QGroundControl
import QGroundControl.Controls
import QGroundControl.ScreenTools

Item {
    id: root

    width:  Math.max(ScreenTools.defaultFontPixelWidth * 36, 320)
    height: Math.max(ScreenTools.defaultFontPixelHeight * 22, 280)

    // -------------------------------------------------------------------------
    // Telemetry Inputs (Defensive Null Checks)
    // -------------------------------------------------------------------------
    readonly property var activeVehicle:  QGroundControl.multiVehicleManager.activeVehicle

    // Live attitude
    readonly property real roll:          (activeVehicle && activeVehicle.roll && !isNaN(activeVehicle.roll.value))
                                          ? activeVehicle.roll.value : 0
    readonly property real pitch:         (activeVehicle && activeVehicle.pitch && !isNaN(activeVehicle.pitch.value))
                                          ? activeVehicle.pitch.value : 0
    readonly property real heading:       (activeVehicle && activeVehicle.heading && !isNaN(activeVehicle.heading.value))
                                          ? activeVehicle.heading.value : 0

    // Performance telemetry
    readonly property real airspeed:      (activeVehicle && activeVehicle.airSpeed && !isNaN(activeVehicle.airSpeed.value))
                                          ? activeVehicle.airSpeed.value : NaN
    readonly property real groundspeed:   (activeVehicle && activeVehicle.groundSpeed && !isNaN(activeVehicle.groundSpeed.value))
                                          ? activeVehicle.groundSpeed.value : NaN
    readonly property real altitude:      (activeVehicle && activeVehicle.altitudeRelative && !isNaN(activeVehicle.altitudeRelative.value))
                                          ? activeVehicle.altitudeRelative.value : NaN
    readonly property real climbRate:     (activeVehicle && activeVehicle.climbRate && !isNaN(activeVehicle.climbRate.value))
                                          ? activeVehicle.climbRate.value : NaN

    // Trigger canvas redraw on attitude or telemetry change
    onRollChanged:        pfdCanvas.requestPaint()
    onPitchChanged:       pfdCanvas.requestPaint()
    onHeadingChanged:     pfdCanvas.requestPaint()
    onAirspeedChanged:    pfdCanvas.requestPaint()
    onGroundspeedChanged: pfdCanvas.requestPaint()
    onAltitudeChanged:    pfdCanvas.requestPaint()
    onClimbRateChanged:   pfdCanvas.requestPaint()

    // -------------------------------------------------------------------------
    // Tactical Glassmorphic Panel Frame
    // -------------------------------------------------------------------------
    Rectangle {
        id: bgFrame
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
    // Header Bar: EFIS / PFD Title & Mode
    // -------------------------------------------------------------------------
    Item {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: ScreenTools.defaultFontPixelHeight * 1.5

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8

            Text {
                text: qsTr("TACTICAL PFD / EFIS")
                font.family: AeroQTheme.fontFamilyHeader
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65
                font.bold: true
                color: AeroQTheme.accentCyan
                font.letterSpacing: 0.8
            }

            Item { Layout.fillWidth: true }

            Text {
                text: root.activeVehicle ? qsTr("ATTITUDE: OK") : qsTr("ATTITUDE: NO LINK")
                font.family: AeroQTheme.fontFamilyMono
                font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.55
                font.bold: true
                color: root.activeVehicle ? AeroQTheme.statusArmed : AeroQTheme.statusWarning
            }
        }
    }

    // -------------------------------------------------------------------------
    // Canvas PFD Rendering
    // -------------------------------------------------------------------------
    Canvas {
        id: pfdCanvas
        anchors.top: headerBar.bottom
        anchors.bottom: telemetryBar.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 4
        renderTarget: Canvas.FramebufferObject

        onPaint: {
            var ctx = getContext("2d")
            ctx.reset()

            var w = width
            var h = height
            var cx = w / 2
            var cy = h / 2

            // Layout definitions
            var tapeWidth = Math.max(w * 0.18, 48)
            var sphereLeft = tapeWidth + 6
            var sphereRight = w - tapeWidth - 16
            var sphereWidth = sphereRight - sphereLeft
            var sphereHeight = h - 28
            var sphereCx = sphereLeft + sphereWidth / 2
            var sphereCy = 14 + sphereHeight / 2
            var pitchPixelScale = sphereHeight / 40.0 // 40 degrees visible

            // =================================================================
            // 1. ARTIFICIAL HORIZON (Sphere Clipped Region)
            // =================================================================
            ctx.save()
            ctx.beginPath()
            ctx.rect(sphereLeft, 14, sphereWidth, sphereHeight)
            ctx.clip()

            // Translate to sphere center & rotate by roll
            ctx.translate(sphereCx, sphereCy)
            ctx.rotate(-root.roll * Math.PI / 180.0)

            // Translate by pitch
            var pitchOffset = root.pitch * pitchPixelScale
            ctx.translate(0, pitchOffset)

            // 1A. Draw Deep Tactical Sky (Cyberpunk Black / Deep Space)
            var skyGrad = ctx.createLinearGradient(0, -sphereHeight * 2, 0, 0)
            skyGrad.addColorStop(0, AeroQTheme.pfdSkyTop)
            skyGrad.addColorStop(1, AeroQTheme.pfdSkyBottom)
            ctx.fillStyle = skyGrad
            ctx.fillRect(-sphereWidth * 2, -sphereHeight * 3, sphereWidth * 4, sphereHeight * 3)

            // Subtle cybernetic vertical grid in sky
            ctx.strokeStyle = "rgba(0, 229, 255, 0.08)"
            ctx.lineWidth = 1.0
            for (var sx = -sphereWidth * 1.5; sx <= sphereWidth * 1.5; sx += 32) {
                ctx.beginPath()
                ctx.moveTo(sx, 0)
                ctx.lineTo(sx, -sphereHeight * 3)
                ctx.stroke()
            }

            // 1B. Draw Deep Tactical Ground (Obsidian Black)
            var gndGrad = ctx.createLinearGradient(0, 0, 0, sphereHeight * 2)
            gndGrad.addColorStop(0, AeroQTheme.pfdGroundTop)
            gndGrad.addColorStop(1, AeroQTheme.pfdGroundBottom)
            ctx.fillStyle = gndGrad
            ctx.fillRect(-sphereWidth * 2, 0, sphereWidth * 4, sphereHeight * 3)

            // 1C. 3D CYBERPUNK WIREFRAME PERSPECTIVE TERRAIN GRID (Blue & Black)
            ctx.save()
            ctx.strokeStyle = AeroQTheme.pfdWireframeGrid
            ctx.lineWidth = 1.0

            // Longitudinal Perspective Lines converging to center at horizon
            for (var gx = -sphereWidth * 2; gx <= sphereWidth * 2; gx += 32) {
                ctx.beginPath()
                ctx.moveTo(gx * 0.15, 0)
                ctx.lineTo(gx * 2.2, sphereHeight * 3)
                ctx.stroke()
            }

            // Transversal Wireframe Grid Rungs
            ctx.strokeStyle = AeroQTheme.pfdWireframeRung
            var rungs = [8, 18, 32, 52, 78, 112, 156, 212, 280, 360, 460]
            for (var ri = 0; ri < rungs.length; ri++) {
                ctx.beginPath()
                ctx.moveTo(-sphereWidth * 2, rungs[ri])
                ctx.lineTo(sphereWidth * 2, rungs[ri])
                ctx.stroke()
            }
            ctx.restore()

            // Horizon Line (Electric Cyan)
            ctx.strokeStyle = AeroQTheme.accentCyan
            ctx.lineWidth = 2.0
            ctx.beginPath()
            ctx.moveTo(-sphereWidth * 1.5, 0)
            ctx.lineTo(-24, 0)
            ctx.moveTo(24, 0)
            ctx.lineTo(sphereWidth * 1.5, 0)
            ctx.stroke()

            // Pitch Ladder (-30 to +30 deg)
            ctx.font = "bold 9px monospace"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"

            for (var deg = -30; deg <= 30; deg += 5) {
                if (deg === 0) continue
                var py = -deg * pitchPixelScale
                var isMajor = (deg % 10 === 0)
                var halfLen = isMajor ? 32 : 18
                var tickH = deg > 0 ? 4 : -4 // Ticks point toward horizon

                ctx.strokeStyle = deg > 0 ? AeroQTheme.accentCyan : Qt.rgba(0, 200 / 255, 1, 0.75)
                ctx.lineWidth = isMajor ? 1.5 : 1.0

                if (deg < 0) {
                    // Dashed lines below horizon
                    ctx.beginPath()
                    for (var x = -halfLen; x <= halfLen; x += 6) {
                        ctx.moveTo(x, py)
                        ctx.lineTo(Math.min(x + 3, halfLen), py)
                    }
                    // End ticks
                    ctx.moveTo(-halfLen, py)
                    ctx.lineTo(-halfLen, py + tickH)
                    ctx.moveTo(halfLen, py)
                    ctx.lineTo(halfLen, py + tickH)
                    ctx.stroke()
                } else {
                    // Solid lines above horizon
                    ctx.beginPath()
                    ctx.moveTo(-halfLen, py)
                    ctx.lineTo(-12, py)
                    ctx.moveTo(12, py)
                    ctx.lineTo(halfLen, py)
                    // End ticks
                    ctx.moveTo(-halfLen, py)
                    ctx.lineTo(-halfLen, py + tickH)
                    ctx.moveTo(halfLen, py)
                    ctx.lineTo(halfLen, py + tickH)
                    ctx.stroke()
                }

                // Numbers for major pitch lines
                if (isMajor) {
                    ctx.fillStyle = deg > 0 ? AeroQTheme.accentCyan : Qt.rgba(0, 200 / 255, 1, 0.85)
                    var label = Math.abs(deg).toString()
                    ctx.fillText(label, -halfLen - 9, py)
                    ctx.fillText(label, halfLen + 9, py)
                }
            }

            ctx.restore() // End horizon transform

            // =================================================================
            // 2. ROLL ARC & INDICATOR
            // =================================================================
            var rollRadius = sphereHeight * 0.44
            ctx.save()
            ctx.beginPath()
            ctx.arc(sphereCx, sphereCy, rollRadius, -Math.PI * 0.85, -Math.PI * 0.15)
            ctx.strokeStyle = AeroQTheme.borderDim
            ctx.lineWidth = 1.5
            ctx.stroke()

            // Roll tick marks: 0, 10, 20, 30, 45, 60
            var rollTicks = [-60, -45, -30, -20, -10, 0, 10, 20, 30, 45, 60]
            for (var i = 0; i < rollTicks.length; i++) {
                var rdeg = rollTicks[i]
                var rad = (-90 + rdeg) * Math.PI / 180.0
                var tLen = (rdeg === 0 || Math.abs(rdeg) === 30 || Math.abs(rdeg) === 60) ? 7 : 4
                var x1 = sphereCx + Math.cos(rad) * rollRadius
                var y1 = sphereCy + Math.sin(rad) * rollRadius
                var x2 = sphereCx + Math.cos(rad) * (rollRadius + tLen)
                var y2 = sphereCy + Math.sin(rad) * (rollRadius + tLen)

                ctx.strokeStyle = rdeg === 0 ? AeroQTheme.accentCyan : AeroQTheme.textSecondary
                ctx.lineWidth = rdeg === 0 ? 2 : 1
                ctx.beginPath()
                ctx.moveTo(x1, y1)
                ctx.lineTo(x2, y2)
                ctx.stroke()
            }

            // Fixed Zero Index (Cyan downward triangle)
            ctx.fillStyle = AeroQTheme.accentCyan
            ctx.beginPath()
            ctx.moveTo(sphereCx, sphereCy - rollRadius - 1)
            ctx.lineTo(sphereCx - 5, sphereCy - rollRadius - 7)
            ctx.lineTo(sphereCx + 5, sphereCy - rollRadius - 7)
            ctx.closePath()
            ctx.fill()

            // Moving Roll Pointer (Rotates with bank angle)
            ctx.save()
            ctx.translate(sphereCx, sphereCy)
            ctx.rotate(-root.roll * Math.PI / 180.0)
            ctx.fillStyle = AeroQTheme.statusArmed
            ctx.beginPath()
            ctx.moveTo(0, -rollRadius + 1)
            ctx.lineTo(-4, -rollRadius + 7)
            ctx.lineTo(4, -rollRadius + 7)
            ctx.closePath()
            ctx.fill()
            ctx.restore()

            ctx.restore() // End Roll Arc

            // =================================================================
            // 3. FIXED CENTER AIRCRAFT SYMBOL (Boresight)
            // =================================================================
            ctx.save()
            ctx.lineWidth = 2.5
            ctx.strokeStyle = AeroQTheme.accentCyan // Tactical neon yellow boresight
            ctx.fillStyle = AeroQTheme.accentCyan

            // Center pip
            ctx.beginPath()
            ctx.arc(sphereCx, sphereCy, 3, 0, Math.PI * 2)
            ctx.fill()

            // Left wing bar with down tick
            ctx.beginPath()
            ctx.moveTo(sphereCx - 36, sphereCy)
            ctx.lineTo(sphereCx - 14, sphereCy)
            ctx.lineTo(sphereCx - 14, sphereCy + 6)
            ctx.stroke()

            // Right wing bar with down tick
            ctx.beginPath()
            ctx.moveTo(sphereCx + 14, sphereCy + 6)
            ctx.lineTo(sphereCx + 14, sphereCy)
            ctx.lineTo(sphereCx + 36, sphereCy)
            ctx.stroke()
            ctx.restore()

            // =================================================================
            // 4. AIRSPEED TAPE (LEFT)
            // =================================================================
            var curSpd = isNaN(root.airspeed) ? (isNaN(root.groundspeed) ? 0 : root.groundspeed) : root.airspeed
            var spdHasData = !isNaN(root.airspeed) || !isNaN(root.groundspeed)

            ctx.save()
            // Tape background
            ctx.fillStyle = AeroQTheme.bgGlassDark
            ctx.fillRect(2, 14, tapeWidth, sphereHeight)
            ctx.strokeStyle = AeroQTheme.borderDim
            ctx.lineWidth = 1
            ctx.strokeRect(2, 14, tapeWidth, sphereHeight)

            // Speed hash marks rolling window
            var spdRange = 20.0
            var spdPixelPerUnit = (sphereHeight * 0.8) / spdRange
            var minSpd = Math.max(0, Math.floor(curSpd - spdRange / 2))
            var maxSpd = Math.ceil(curSpd + spdRange / 2)

            ctx.save()
            ctx.beginPath()
            ctx.rect(2, 14, tapeWidth, sphereHeight)
            ctx.clip()

            ctx.font = "9px monospace"
            ctx.textAlign = "right"
            ctx.textBaseline = "middle"

            for (var s = minSpd; s <= maxSpd; s++) {
                if (s < 0) continue
                var sy = sphereCy - (s - curSpd) * spdPixelPerUnit
                var sMajor = (s % 5 === 0)
                var sLen = sMajor ? 9 : 5

                ctx.strokeStyle = sMajor ? AeroQTheme.accentCyan : AeroQTheme.textMuted
                ctx.lineWidth = sMajor ? 1.5 : 1.0
                ctx.beginPath()
                ctx.moveTo(tapeWidth + 2 - sLen, sy)
                ctx.lineTo(tapeWidth + 2, sy)
                ctx.stroke()

                if (sMajor) {
                    ctx.fillStyle = AeroQTheme.textPrimary
                    ctx.fillText(s.toString(), tapeWidth - 9, sy)
                }
            }
            ctx.restore()

            // Speed Pointer & Digital Readout Box
            var spdBoxH = 18
            var spdBoxW = tapeWidth - 4
            ctx.fillStyle = Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.95)
            ctx.strokeStyle = AeroQTheme.accentCyan
            ctx.lineWidth = 1.5
            ctx.beginPath()
            ctx.rect(3, sphereCy - spdBoxH / 2, spdBoxW, spdBoxH)
            ctx.fill()
            ctx.stroke()

            ctx.fillStyle = AeroQTheme.accentCyan
            ctx.font = "bold 10px monospace"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText(spdHasData ? curSpd.toFixed(1) : "--", 3 + spdBoxW / 2, sphereCy)

            // Header label
            ctx.font = "8px sans-serif"
            ctx.fillStyle = AeroQTheme.textSecondary
            ctx.textAlign = "left"
            ctx.fillText("SPD m/s", 5, 23)
            ctx.restore()

            // =================================================================
            // 5. ALTITUDE TAPE (RIGHT)
            // =================================================================
            var curAlt = isNaN(root.altitude) ? 0 : root.altitude
            var altHasData = !isNaN(root.altitude)
            var altX = w - tapeWidth - 14

            ctx.save()
            // Tape background
            ctx.fillStyle = AeroQTheme.bgGlassDark
            ctx.fillRect(altX, 14, tapeWidth, sphereHeight)
            ctx.strokeStyle = AeroQTheme.borderDim
            ctx.lineWidth = 1
            ctx.strokeRect(altX, 14, tapeWidth, sphereHeight)

            // Altitude hash marks rolling window
            var altRange = 30.0
            var altPixelPerUnit = (sphereHeight * 0.8) / altRange
            var minAlt = Math.floor(curAlt - altRange / 2)
            var maxAlt = Math.ceil(curAlt + altRange / 2)

            ctx.save()
            ctx.beginPath()
            ctx.rect(altX, 14, tapeWidth, sphereHeight)
            ctx.clip()

            ctx.font = "9px monospace"
            ctx.textAlign = "left"
            ctx.textBaseline = "middle"

            for (var a = minAlt; a <= maxAlt; a++) {
                if (a % 2 !== 0) continue
                var ay = sphereCy - (a - curAlt) * altPixelPerUnit
                var aMajor = (a % 10 === 0)
                var aLen = aMajor ? 9 : 5

                ctx.strokeStyle = aMajor ? AeroQTheme.accentCyan : AeroQTheme.textMuted
                ctx.lineWidth = aMajor ? 1.5 : 1.0
                ctx.beginPath()
                ctx.moveTo(altX, ay)
                ctx.lineTo(altX + aLen, ay)
                ctx.stroke()

                if (aMajor) {
                    ctx.fillStyle = AeroQTheme.textPrimary
                    ctx.fillText(a.toString(), altX + 11, ay)
                }
            }
            ctx.restore()

            // Altitude Pointer & Digital Readout Box
            var altBoxH = 18
            var altBoxW = tapeWidth - 4
            ctx.fillStyle = Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.95)
            ctx.strokeStyle = AeroQTheme.accentCyan
            ctx.lineWidth = 1.5
            ctx.beginPath()
            ctx.rect(altX + 2, sphereCy - altBoxH / 2, altBoxW, altBoxH)
            ctx.fill()
            ctx.stroke()

            ctx.fillStyle = AeroQTheme.accentCyan
            ctx.font = "bold 10px monospace"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"
            ctx.fillText(altHasData ? curAlt.toFixed(1) : "--", altX + 2 + altBoxW / 2, sphereCy)

            // Header label
            ctx.font = "8px sans-serif"
            ctx.fillStyle = AeroQTheme.textSecondary
            ctx.textAlign = "right"
            ctx.fillText("ALT m", altX + tapeWidth - 4, 23)
            ctx.restore()

            // =================================================================
            // 6. VERTICAL SPEED INDICATOR (VSI) - TAPE ALONGSIDE ALTITUDE
            // =================================================================
            var vsiX = w - 12
            var vsiW = 9
            var vsiVal = isNaN(root.climbRate) ? 0 : root.climbRate
            var vsiMax = 5.0 // scale +/- 5 m/s
            var clampedVsi = Math.max(-vsiMax, Math.min(vsiMax, vsiVal))
            var vsiBarH = (clampedVsi / vsiMax) * (sphereHeight * 0.4)

            ctx.save()
            ctx.fillStyle = AeroQTheme.bgGlassDark
            ctx.fillRect(vsiX, 14, vsiW, sphereHeight)
            ctx.strokeStyle = AeroQTheme.borderDim
            ctx.lineWidth = 1
            ctx.strokeRect(vsiX, 14, vsiW, sphereHeight)

            // Zero center mark
            ctx.strokeStyle = AeroQTheme.accentCyan
            ctx.beginPath()
            ctx.moveTo(vsiX, sphereCy)
            ctx.lineTo(vsiX + vsiW, sphereCy)
            ctx.stroke()

            // VSI Bar Fill
            if (Math.abs(vsiVal) > 0.05) {
                ctx.fillStyle = vsiVal > 0 ? AeroQTheme.statusArmed : AeroQTheme.statusDisarmed
                if (vsiBarH > 0) {
                    ctx.fillRect(vsiX + 1, sphereCy - vsiBarH, vsiW - 2, vsiBarH)
                } else {
                    ctx.fillRect(vsiX + 1, sphereCy, vsiW - 2, -vsiBarH)
                }
            }
            ctx.restore()

            // =================================================================
            // 7. HEADING COMPASS TAPE (TOP)
            // =================================================================
            var compW = sphereWidth
            var compX = sphereLeft
            var compY = 2
            var compH = 13
            var curHdg = (root.heading % 360 + 360) % 360
            var hdgPxPerDeg = compW / 90.0 // 90 degrees visible

            ctx.save()
            ctx.beginPath()
            ctx.rect(compX, compY, compW, compH)
            ctx.clip()

            ctx.fillStyle = Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.7)
            ctx.fillRect(compX, compY, compW, compH)

            ctx.font = "bold 8px monospace"
            ctx.textAlign = "center"
            ctx.textBaseline = "middle"

            for (var hdeg = -180; hdeg <= 540; hdeg += 15) {
                var diff = hdeg - curHdg
                var hx = sphereCx + diff * hdgPxPerDeg
                if (hx < compX - 20 || hx > compX + compW + 20) continue

                var normDeg = (hdeg % 360 + 360) % 360
                var card = ""
                if (normDeg === 0) card = "N"
                else if (normDeg === 90) card = "E"
                else if (normDeg === 180) card = "S"
                else if (normDeg === 270) card = "W"

                ctx.strokeStyle = card !== "" ? AeroQTheme.accentCyan : AeroQTheme.textMuted
                ctx.lineWidth = card !== "" ? 1.5 : 1.0
                ctx.beginPath()
                ctx.moveTo(hx, compY + compH - 4)
                ctx.lineTo(hx, compY + compH)
                ctx.stroke()

                ctx.fillStyle = card !== "" ? AeroQTheme.accentCyan : AeroQTheme.textSecondary
                ctx.fillText(card !== "" ? card : (normDeg / 10).toFixed(0), hx, compY + 5)
            }
            ctx.restore()

            // Heading Center Pointer & Digits
            ctx.fillStyle = AeroQTheme.accentCyan
            ctx.beginPath()
            ctx.moveTo(sphereCx, compY + compH + 1)
            ctx.lineTo(sphereCx - 4, compY + compH + 5)
            ctx.lineTo(sphereCx + 4, compY + compH + 5)
            ctx.closePath()
            ctx.fill()

            // Tactical Corner Brackets on PFD
            AeroQTheme.drawTacticalBracket(ctx, 1, 1, w - 2, h - 2, 8, AeroQTheme.accentCyan)
        }
    }

    // -------------------------------------------------------------------------
    // Bottom Digital Readouts Banner
    // -------------------------------------------------------------------------
    Item {
        id: telemetryBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: ScreenTools.defaultFontPixelHeight * 1.5

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            // Pitch Readout
            RowLayout {
                spacing: 2
                Text { text: "P:"; font.family: AeroQTheme.fontFamilyMono; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.6; font.bold: true; color: AeroQTheme.textSecondary }
                Text { text: AeroQTheme.formatDegrees(root.pitch); font.family: AeroQTheme.fontFamilyMono; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65; font.bold: true; color: AeroQTheme.textPrimary }
            }

            // Roll Readout
            RowLayout {
                spacing: 2
                Text { text: "R:"; font.family: AeroQTheme.fontFamilyMono; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.6; font.bold: true; color: AeroQTheme.textSecondary }
                Text { text: AeroQTheme.formatDegrees(root.roll); font.family: AeroQTheme.fontFamilyMono; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65; font.bold: true; color: AeroQTheme.textPrimary }
            }

            // Yaw / Heading Readout
            RowLayout {
                spacing: 2
                Text { text: "HDG:"; font.family: AeroQTheme.fontFamilyMono; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.6; font.bold: true; color: AeroQTheme.textSecondary }
                Text { text: AeroQTheme.formatHeading(root.heading); font.family: AeroQTheme.fontFamilyMono; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65; font.bold: true; color: AeroQTheme.accentCyan }
            }

            Item { Layout.fillWidth: true }

            // Vertical Speed Readout
            RowLayout {
                spacing: 2
                Text { text: "VSI:"; font.family: AeroQTheme.fontFamilyMono; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.6; font.bold: true; color: AeroQTheme.textSecondary }
                Text { text: AeroQTheme.formatSpeed(root.climbRate); font.family: AeroQTheme.fontFamilyMono; font.pixelSize: ScreenTools.defaultFontPixelHeight * 0.65; font.bold: true; color: AeroQTheme.textPrimary }
            }
        }
    }
}

