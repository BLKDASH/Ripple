import QtQuick
import CWY.Theme

Rectangle {
    id: root
    radius: 8

    property real glassOpacity: Theme.glassOpacity

    color: {
        var base = Theme.panelBg
        return Qt.rgba(base.r, base.g, base.b, root.glassOpacity)
    }
    border.color: {
        var base = Theme.text
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
        opacity: Theme.text.r > 0.5 ? 0.08 : 0.12
    }
}
