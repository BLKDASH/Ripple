import QtQuick
import QtQuick.Controls
import Ripple.Theme
import Ripple.NotificationManager

// Visual notification overlay. The actual notification queue lives in the
// NotificationManager singleton so any component can trigger a toast without
// dynamic scoping.
Item {
    id: root
    anchors.fill: parent
    z: 9999

    Column {
        id: toastColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 8
        spacing: 4
        width: parent.width

        Repeater {
            model: NotificationManager.model

            delegate: Rectangle {
                id: toast
                required property int    index
                required property int    uid
                required property string message
                required property string type
                required property int    duration

                // Auto-width: content-driven, capped at parent width
                property int _pad: 28  // leftMargin(8) + icon(~14) + spacing(6)
                property real _contentW: toastLabel.contentWidth + _pad
                width: Math.min(_contentW, toastColumn.width - 16)
                height: Math.max(28, toastLabel.implicitHeight + 10)
                radius: 5
                opacity: 0
                transform: Translate { id: slideShift; y: -8 }
                property bool _ready: false

                anchors.horizontalCenter: parent.horizontalCenter

                readonly property color _bg: {
                    switch (type) {
                        case "error":   return Theme.error
                        case "warning": return Theme.warning
                        case "success": return Theme.success
                        default:        return Theme.accent
                    }
                }
                readonly property string _icon: {
                    switch (type) {
                        case "error":   return "✕"
                        case "warning": return "⚠"
                        case "success": return "✓"
                        default:        return "ℹ"
                    }
                }

                color: Qt.rgba(_bg.r, _bg.g, _bg.b, 0.78)
                border.color: Qt.rgba(_bg.r, _bg.g, _bg.b, 0.3)
                border.width: 1

                Row {
                    id: toastRow
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 8
                    spacing: 6
                    Label {
                        text: toast._icon
                        color: "white"
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        id: toastLabel
                        text: toast.message
                        color: "white"
                        font.pixelSize: Theme.fontSize
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        anchors.verticalCenter: parent.verticalCenter
                        width: toast.width - toast._pad
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toast._dismiss()
                }

                function _dismiss() {
                    dismissTimer.stop()
                    fadeOut.start()
                }

                ParallelAnimation {
                    id: fadeIn
                    NumberAnimation { target: toast; property: "opacity"; to: 1.0; duration: 200; easing.type: Easing.OutCubic }
                    NumberAnimation { target: slideShift; property: "y"; to: 0; duration: 220; easing.type: Easing.OutBack }
                    onFinished: toast._ready = true
                }

                ParallelAnimation {
                    id: fadeOut
                    NumberAnimation { target: toast; property: "opacity"; to: 0.0; duration: 180; easing.type: Easing.InCubic }
                    NumberAnimation { target: slideShift; property: "y"; to: -8; duration: 180; easing.type: Easing.InCubic }
                    onFinished: NotificationManager.remove(toast.uid)
                }

                Timer {
                    id: dismissTimer
                    interval: toast.duration
                    running: false
                    repeat: false
                    onTriggered: fadeOut.start()
                }

                Component.onCompleted: {
                    fadeIn.start()
                    dismissTimer.start()
                }
            }
        }
    }
}
