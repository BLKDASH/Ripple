import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.AppSettings
import CWY.Serial
import CWY.Theme
import CWY.NotificationManager

Rectangle {
    id: root
    color: Theme.panelBg
    border.color: Theme.border
    radius: 4

    property bool hexMode: false
    property bool appendCr: false
    property bool appendLf: false
    property bool cyclicSend: false
    property int cyclicInterval: 1000

    Component.onCompleted: {
        hexMode = AppSettings.sendHexMode
        appendCr = AppSettings.sendAppendCr
        appendLf = AppSettings.sendAppendLf
        cyclicSend = AppSettings.sendCyclicSend
        cyclicInterval = AppSettings.sendCyclicInterval
    }

    onHexModeChanged: AppSettings.sendHexMode = hexMode
    onAppendCrChanged: AppSettings.sendAppendCr = appendCr
    onAppendLfChanged: AppSettings.sendAppendLf = appendLf
    onCyclicSendChanged: AppSettings.sendCyclicSend = cyclicSend
    onCyclicIntervalChanged: AppSettings.sendCyclicInterval = cyclicInterval

    signal sent()

    function send() {
        if (!SerialPort.isOpen) {
            NotificationManager.error(qsTr("Serial port is not open"))
            return
        }

        var payload = sendInput.text
        if (root.hexMode) {
            payload = payload.replace(/\s/g, "")
            if (payload.length % 2 !== 0) {
                NotificationManager.error(qsTr("Invalid HEX: odd number of digits"))
                return
            }
            if (!/^[0-9A-Fa-f]*$/.test(payload)) {
                NotificationManager.error(qsTr("Invalid HEX: only 0-9, A-F allowed"))
                return
            }
        }

        if (root.appendCr) payload += "\r"
        if (root.appendLf) payload += "\n"

        var ok = root.hexMode ? SerialPort.sendHex(sendInput.text) : SerialPort.sendText(payload)
        if (ok) root.sent()
    }

    function setContent(text, asHex) {
        sendInput.text = text
        root.hexMode = asHex
    }

    function clearInput() {
        sendInput.text = ""
        sendInput.validInput = true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Label {
            text: qsTr("Send")
            font.bold: true
            color: Theme.text
        }

        // Send input with custom scrollbar
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.inputBg
            border.color: sendInput.validInput ? Theme.border : Theme.error
            radius: 4
            clip: true

            Flickable {
                id: sendFlickable
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: sendInput.width
                contentHeight: sendInput.height
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true

                TextEdit {
                    id: sendInput
                    width: sendFlickable.width
                    height: Math.max(implicitHeight, sendFlickable.height)
                    color: Theme.text
                    wrapMode: Text.Wrap
                    font.family: "Consolas"
                    font.pixelSize: 13
                    textFormat: Text.PlainText
                    property bool validInput: true

                    onTextChanged: {
                        if (root.hexMode) {
                            var cleaned = text.replace(/\s/g, "")
                            validInput = /^[0-9A-Fa-f]*$/.test(cleaned) && (cleaned.length % 2 === 0 || cleaned.length === 0)
                        } else {
                            validInput = true
                        }
                    }

                    Keys.onPressed: (event) => {
                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                            && (event.modifiers & Qt.ControlModifier)) {
                            root.send()
                            event.accepted = true
                        }
                    }
                }

                ScrollBar.vertical: CustomScrollBar {
                    orientation: Qt.Vertical
                    policy: sendFlickable.contentHeight > sendFlickable.height + 5 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }
        }

        // Options
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            rowSpacing: 4
            columnSpacing: 12

            CheckBox {
                text: qsTr("HEX")
                checked: root.hexMode
                onCheckedChanged: root.hexMode = checked
            }
            CheckBox {
                text: qsTr("Append \\r")
                checked: root.appendCr
                onCheckedChanged: root.appendCr = checked
            }
            CheckBox {
                text: qsTr("Append \\n")
                checked: root.appendLf
                onCheckedChanged: root.appendLf = checked
            }
            CheckBox {
                text: qsTr("Cyclic")
                checked: root.cyclicSend
                onCheckedChanged: root.cyclicSend = checked
            }
        }

        // Cyclic interval
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            enabled: root.cyclicSend
            opacity: root.cyclicSend ? 1.0 : 0.5

            Label {
                text: qsTr("Interval (ms)")
                color: Theme.text
                font.pixelSize: 12
            }
            SpinBox {
                id: intervalSpin
                Layout.fillWidth: true
                from: 10
                to: 60000
                value: root.cyclicInterval
                onValueModified: root.cyclicInterval = value
            }
        }

        Button {
            text: qsTr("Send (Ctrl+Enter)")
            highlighted: true
            Layout.fillWidth: true
            onClicked: root.send()
        }

        Item { Layout.fillHeight: true }
    }

    Timer {
        id: cyclicTimer
        interval: root.cyclicInterval
        repeat: true
        running: root.cyclicSend && SerialPort.isOpen
        onTriggered: root.send()
    }
}
