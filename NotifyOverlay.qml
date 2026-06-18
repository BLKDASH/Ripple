import QtQuick
import QtQuick.Controls
import CWY.Theme
import CWY.NotificationManager

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
        anchors.topMargin: 12
        spacing: 6
        width: Math.min(520, parent.width - 24)

        Repeater {
            model: NotificationManager.model

            delegate: Rectangle {
                id: toast
                required property int    index
                required property int    uid
                required property string message
                required property string type
                required property int    duration

                width: toastColumn.width
                height: Math.max(40, toastLabel.implicitHeight + 22)
                radius: 6
                opacity: 0
                transform: Translate { id: slideShift; y: -10 }
                property bool _ready: false

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

                color: _bg
                border.color: Qt.darker(_bg, 1.15)
                border.width: 1

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10
                    Label {
                        text: toast._icon
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Label {
                        id: toastLabel
                        text: toast.message
                        color: "white"
                        font.pixelSize: 13
                        wrapMode: Text.Wrap
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 50
                    }
                }

                MouseArea {
                    anchors { top: parent.top; right: parent.right; bottom: parent.bottom }
                    width: 36
                    cursorShape: Qt.PointingHandCursor
                    onClicked: toast._dismiss()
                    Label {
                        anchors.centerIn: parent
                        text: "✕"
                        color: "white"
                        font.pixelSize: 13
                        opacity: 0.7
                    }
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
                    NumberAnimation { target: slideShift; property: "y"; to: -10; duration: 180; easing.type: Easing.InCubic }
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
