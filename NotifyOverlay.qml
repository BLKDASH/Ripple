import QtQuick
import QtQuick.Controls

// Unified notification overlay — drop-in anywhere in the window to get:
//   notify.error("message")   notify.warning("message")
//   notify.success("message")  notify.info("message")
// Deeper children reach it via QML dynamic scoping (just use `notify` id directly).
Item {
    id: root
    anchors.fill: parent
    z: 9999

    // ── public API ──────────────────────────────────────────────
    function error(msg, duration)   { show(msg, "error",   duration || 5000) }
    function warning(msg, duration) { show(msg, "warning", duration || 3500) }
    function success(msg, duration) { show(msg, "success", duration || 2500) }
    function info(msg, duration)    { show(msg, "info",    duration || 2500) }

    // ── internal model ──────────────────────────────────────────
    property int _uidSeq: 0

    function show(msg, type, duration) {
        if (!msg || msg === "") return
        _uidSeq++
        notifyModel.append({
            uid: _uidSeq,
            message: msg,
            type: type,
            duration: duration
        })
    }

    ListModel { id: notifyModel }

    // ── visual layer ────────────────────────────────────────────
    Column {
        id: toastColumn
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 12
        spacing: 6
        width: Math.min(520, parent.width - 24)

        Repeater {
            model: notifyModel

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
                // slide-in offset — Column manages y, so we translate
                transform: Translate { id: slideShift; y: -10 }
                // track whether we've been fully set up (avoid double-dismiss)
                property bool _ready: false

                // colour per type — Material Design standard swatches
                readonly property color _bg: {
                    switch (type) {
                        case "error":   return "#F44336"
                        case "warning": return "#FF9800"
                        case "success": return "#4CAF50"
                        default:        return _accent
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

                // close button
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

                function _removeFromModel() {
                    for (var i = 0; i < notifyModel.count; i++) {
                        if (notifyModel.get(i).uid === uid) {
                            notifyModel.remove(i)
                            break
                        }
                    }
                }

                function _dismiss() {
                    dismissTimer.stop()
                    fadeOut.start()
                }

                // animations
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
                    onFinished: toast._removeFromModel()
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
