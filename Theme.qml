pragma Singleton
import QtQuick
import Ripple.AppSettings

// Centralized theme singleton for Ripple.
// This replaces the scattered dynamic-scope colour references used by the
// previous implementation and lets every component access the same palette
// without depending on ids declared in Main.qml.
QtObject {
    id: root

    // Public toggle. Reads persisted value on startup so the correct theme
    // is active before the window becomes visible (no flash of default UI).
    property bool darkTheme: AppSettings.darkTheme

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

    // Layout constants — unified radius and spacing across all panels
    readonly property int radiusPanel: 16      // outer panel corners
    readonly property int radiusInput: 6       // input field corners
    readonly property int spacingPanel: 12     // panel inner margin
    readonly property int spacingSection: 10   // gap between logical sections
    readonly property int spacingTight: 6      // compact inline spacing

    // Font — centralized sizes and monospace family so every component
    // picks up the same values. Change here and the whole UI follows.
    readonly property string fontFamily: "Microsoft YaHei"
    readonly property string monoFontFamily: "Consolas"
    readonly property int fontSize: 12
    readonly property int fontSizeMedium: 13
    readonly property int fontSizeLarge: 16
}
