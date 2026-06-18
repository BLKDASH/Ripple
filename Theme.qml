pragma Singleton
import QtQuick

// Centralized theme singleton for CWY.
// This replaces the scattered dynamic-scope colour references used by the
// previous implementation and lets every component access the same palette
// without depending on ids declared in Main.qml.
QtObject {
    id: root

    // Public toggle. Main.qml binds its own darkTheme property to this value
    // and persists it through Settings.
    property bool darkTheme: false

    // Core palette
    readonly property color panelBg:  darkTheme ? "#202020" : "#F3F3F3"
    readonly property color inputBg:  darkTheme ? "#181818" : "#FFFFFF"
    readonly property color border:   darkTheme ? "#383838" : "#E0E0E0"
    readonly property color text:     darkTheme ? "#E8E8E8" : "#151515"
    readonly property color accent:   darkTheme ? "#60CDFF" : "#005FB8"
    readonly property color success:  "#2EA043"
    readonly property color error:    "#F85149"
    readonly property color warning:  "#D29922"

    // FluentWinUI3-friendly ApplicationWindow palette mapping.
    // Components that still want to delegate to the system style can use these
    // instead of the custom palette above.
    readonly property color window:        panelBg
    readonly property color windowText:    text
    readonly property color base:          inputBg
    readonly property color button:        panelBg
    readonly property color buttonText:    text
    readonly property color highlight:     accent
    readonly property color highlightedText: darkTheme ? "#000000" : "#FFFFFF"
    readonly property color toolTipBase:   panelBg
    readonly property color toolTipText:   text

    // Extra helpers used by glass panels / notifications
    readonly property real glassOpacity: 0.72
}
