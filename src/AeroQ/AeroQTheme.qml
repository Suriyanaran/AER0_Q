pragma Singleton

import QtQuick

QtObject {
    id: root

    // =========================================================================
    // COLOR PALETTE - TACTICAL CYBERPUNK / GLASSMORPHIC
    // =========================================================================
    readonly property color bgDark:              "#03060d"
    readonly property color bgCard:              "#070c17"
    readonly property color bgGlass:             Qt.rgba(7 / 255, 12 / 255, 23 / 255, 0.85)
    readonly property color bgGlassLight:        Qt.rgba(12 / 255, 21 / 255, 38 / 255, 0.70)
    readonly property color bgGlassDark:         Qt.rgba(3 / 255, 6 / 255, 13 / 255, 0.90)

    // Accent and border colors
    readonly property color accentCyan:          "#00e5ff"
    readonly property color accentCyanGlow:      Qt.rgba(0, 229 / 255, 1, 0.45)
    readonly property color accentCyanDim:       Qt.rgba(0, 229 / 255, 1, 0.20)
    readonly property color borderBlue:          "#1f4068"
    readonly property color borderCyan:          "#00e5ff"
    readonly property color borderDim:           Qt.rgba(31 / 255, 64 / 255, 104 / 255, 0.60)

    // Status colors
    readonly property color statusArmed:         "#00ff66"
    readonly property color statusArmedGlow:     Qt.rgba(0, 1, 102 / 255, 0.40)
    readonly property color statusDisarmed:      "#ff2244"
    readonly property color statusDisarmedGlow:  Qt.rgba(1, 34 / 255, 68 / 255, 0.40)
    readonly property color statusWarning:       "#ff9900"
    readonly property color statusWarningGlow:   Qt.rgba(1, 153 / 255, 0, 0.40)
    readonly property color statusConnecting:    "#00b0ff"

    // Text colors
    readonly property color textPrimary:         "#e0f7fa"
    readonly property color textSecondary:       "#648ba8"
    readonly property color textMuted:           "#3b5266"
    readonly property color textCyan:            "#00e5ff"

    // PFD horizon colors (Cyberpunk Wireframe Blue & Black)
    readonly property color pfdSkyTop:           "#010308"
    readonly property color pfdSkyBottom:        "#040c1a"
    readonly property color pfdGroundTop:        "#020610"
    readonly property color pfdGroundBottom:     "#010206"
    readonly property color pfdWireframeGrid:    Qt.rgba(0, 229 / 255, 1, 0.22)
    readonly property color pfdWireframeRung:    Qt.rgba(0, 229 / 255, 1, 0.28)

    // =========================================================================
    // TYPOGRAPHY (Fallbacks to local system fonts - NO internet downloads)
    // =========================================================================
    readonly property string fontFamilyHeader:    "Orbitron, Segoe UI, Roboto, Helvetica, Arial, sans-serif"
    readonly property string fontFamilyTelemetry: "Rajdhani, Eurostile, Segoe UI Semibold, sans-serif"
    readonly property string fontFamilyMono:      "JetBrains Mono, Consolas, Lucida Console, Courier New, monospace"

    // =========================================================================
    // HELPER FUNCTIONS
    // =========================================================================
    function formatAltitude(val) {
        if (val === undefined || val === null || isNaN(val)) return "--"
        return val.toFixed(1) + " m"
    }

    function formatSpeed(val) {
        if (val === undefined || val === null || isNaN(val)) return "--"
        return val.toFixed(1) + " m/s"
    }

    function formatDegrees(val) {
        if (val === undefined || val === null || isNaN(val)) return "--"
        return (val >= 0 ? "+" : "") + val.toFixed(1) + "°"
    }

    function formatHeading(val) {
        if (val === undefined || val === null || isNaN(val)) return "---°"
        var norm = ((val % 360) + 360) % 360
        var s = Math.round(norm).toString()
        while (s.length < 3) s = "0" + s
        return s + "°"
    }

    function formatVoltage(val) {
        if (val === undefined || val === null || isNaN(val)) return "--.- V"
        return val.toFixed(1) + " V"
    }

    function formatPercent(val) {
        if (val === undefined || val === null || isNaN(val)) return "--%"
        return Math.round(val) + "%"
    }

    function formatTimer(seconds) {
        if (seconds === undefined || seconds === null || isNaN(seconds) || seconds < 0) return "00:00:00"
        var sec_num = parseInt(seconds, 10)
        var hours   = Math.floor(sec_num / 3600)
        var minutes = Math.floor((sec_num - (hours * 3600)) / 60)
        var secs    = sec_num - (hours * 3600) - (minutes * 60)
        var hStr = hours < 10 ? "0" + hours : hours.toString()
        var mStr = minutes < 10 ? "0" + minutes : minutes.toString()
        var sStr = secs < 10 ? "0" + secs : secs.toString()
        return hStr + ":" + mStr + ":" + sStr
    }

    // Helper to draw tactical glassmorphic corner brackets on a 2D canvas
    function drawTacticalBracket(ctx, x, y, w, h, bracketLen, color) {
        ctx.save()
        ctx.strokeStyle = color
        ctx.lineWidth = 1.5
        ctx.beginPath()

        // Top-left
        ctx.moveTo(x, y + bracketLen)
        ctx.lineTo(x, y)
        ctx.lineTo(x + bracketLen, y)

        // Top-right
        ctx.moveTo(x + w - bracketLen, y)
        ctx.lineTo(x + w, y)
        ctx.lineTo(x + w, y + bracketLen)

        // Bottom-right
        ctx.moveTo(x + w, y + h - bracketLen)
        ctx.lineTo(x + w, y + h)
        ctx.lineTo(x + w - bracketLen, y + h)

        // Bottom-left
        ctx.moveTo(x + bracketLen, y + h)
        ctx.lineTo(x, y + h)
        ctx.lineTo(x, y + h - bracketLen)

        ctx.stroke()
        ctx.restore()
    }
}

