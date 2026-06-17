import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.Serial

Rectangle {
    id: root
    color: themePalette.panel
    border.color: themePalette.border
    radius: 4

    property var themePalette

    property bool hexMode: false
    property bool appendCr: false
    property bool appendLf: false
    property bool cyclicSend: false
    property int cyclicInterval: 1000

    signal sent()

    function send() {
        if (!SerialPort.isOpen) {
            errorPopup.text = qsTr("Serial port is not open")
            errorPopup.open()
            return
        }

        var payload = sendInput.text
        if (root.hexMode) {
            payload = payload.replace(/\s/g, "")
            if (payload.length % 2 !== 0) {
                errorPopup.text = qsTr("Invalid HEX: odd number of digits")
                errorPopup.open()
                return
            }
            if (!/^[0-9A-Fa-f]*$/.test(payload)) {
                errorPopup.text = qsTr("Invalid HEX: only 0-9, A-F allowed")
                errorPopup.open()
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

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Label {
            text: qsTr("Send")
            font.bold: true
            color: themePalette.text
        }

        // Send input with custom scrollbar
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: themePalette.background
            border.color: sendInput.validInput ? themePalette.border : themePalette.error
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
                    color: themePalette.text
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

                    Keys.onReturnPressed: (event) => {
                        if (event.modifiers & Qt.ControlModifier) {
                            root.send()
                            event.accepted = true
                        }
                    }
                }

                ScrollBar.vertical: CustomScrollBar {
                    themePalette: root.themePalette
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
                color: themePalette.text
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
        onRunningChanged: {
            if (running) restart()
        }
    }
}
