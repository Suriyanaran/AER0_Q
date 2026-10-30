pragma Singleton
import QtQuick

QtObject {
    id: root
    readonly property real defaultFontPixelHeight: 16
    readonly property real defaultFontPixelWidth: 8
    readonly property real screenWidth: 1280
    readonly property real screenHeight: 760
    readonly property bool isMobile: false
    readonly property bool isFakeMobile: false
}

