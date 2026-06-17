import QtQuick
import QtQuick.Controls

ScrollBar {
    id: root

    property var themePalette

    contentItem: Rectangle {
        implicitWidth: root.orientation === Qt.Vertical ? 6 : 0
        implicitHeight: root.orientation === Qt.Horizontal ? 6 : 0
        radius: 3
        color: {
            if (!root.themePalette) return "#808080"
            var base = root.themePalette.text
            return Qt.rgba(base.r, base.g, base.b, root.pressed ? 0.7 : (root.hovered ? 0.55 : 0.35))
        }
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    background: Rectangle {
        implicitWidth: root.orientation === Qt.Vertical ? 6 : 0
        implicitHeight: root.orientation === Qt.Horizontal ? 6 : 0
        color: {
            if (!root.themePalette) return "#00000000"
            var base = root.themePalette.border
            return Qt.rgba(base.r, base.g, base.b, 0.15)
        }
        radius: 3
    }
}
