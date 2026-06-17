import QtQuick

Rectangle {
    id: root
    radius: 8

    property var themePalette
    property real glassOpacity: 0.72

    color: {
        if (!themePalette) return "#B0000000"
        var base = themePalette.panel
        return Qt.rgba(base.r, base.g, base.b, root.glassOpacity)
    }
    border.color: {
        if (!themePalette) return "#20FFFFFF"
        var base = themePalette.border
        return Qt.rgba(base.r, base.g, base.b, 0.3)
    }

    // Top highlight for glass feel
    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: parent.radius * 0.4
        radius: parent.radius * 0.4
        color: "white"
        opacity: root.themePalette ? (root.themePalette.text.r > 0.5 ? 0.08 : 0.12) : 0.1
    }
}
