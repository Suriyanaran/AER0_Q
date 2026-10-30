# ============================================================================
# Aero-Q Tactical Avionics & Defense Suite QML Module
# ============================================================================

qt_add_library(AeroQModule STATIC)

qt_add_qml_module(AeroQModule
    URI AeroQ
    VERSION 1.0
    RESOURCE_PREFIX /qml
    QML_FILES
        AeroQHud.qml
        AeroQTheme.qml
        AeroQTopBar.qml
        AeroQPfd.qml
        AeroQHealthPanel.qml
        AeroQTelemetryChart.qml
        AeroQConnectionDeck.qml
        AeroQEventConsole.qml
        AeroQFlightControls.qml
        AeroQFpvOverlay.qml
        AeroQFleetPanel.qml
        AeroQSosPanel.qml
    NO_PLUGIN
)

target_link_libraries(${CMAKE_PROJECT_NAME}
    PRIVATE
        AeroQModule
)

