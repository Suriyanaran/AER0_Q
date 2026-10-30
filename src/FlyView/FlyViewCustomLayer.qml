import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import QtLocation
import QtPositioning
import QtQuick.Window
import QtQml.Models

import QGroundControl
import QGroundControl.Controls
import QGroundControl.FlyView
import QGroundControl.FlightMap

import AeroQ

Item {
    id: _root

    property var occluders              // FlyViewOccluders: where the upstream widgets are, use these to position your controls
    property var customOccluders: aeroHud.visible ? aeroHud.customOccluders : []
    property var mapControl             // FlyViewMap, or FlyViewGeoMapAdapter with the GeoMap engine: add GeoMap items through QGCCorePlugin::customGeoMapItems

    // AERO-Q Tactical HUD Overlay
    AeroQHud {
        id:                 aeroHud
        anchors.fill:       parent
        occluders:          _root.occluders
        mapControl:         _root.mapControl
    }
}
