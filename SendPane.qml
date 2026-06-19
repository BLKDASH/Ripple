import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.AppSettings
import CWY.Serial
import CWY.Theme
import CWY.NotificationManager

MainPanel {
    id: root

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
        anchors.margins: Theme.spacingPanel
        spacing: Theme.spacingSection

        Label {
            text: qsTr("Send")
            font.bold: true
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.text
        }

        // Send input with custom scrollbar
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.inputBg
            border.color: sendInput.validInput ? Theme.border : Theme.error
            radius: Theme.radiusInput
            clip: true

            // Placeholder
            Label {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.margins: 8
                text: qsTr("Enter data to send...")
                color: Theme.text
                opacity: 0.35
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeMedium
                visible: sendInput.text.length === 0 && !sendInput.activeFocus
            }

            Flickable {
                id: sendFlickable
                anchors.fill: parent
                anchors.margins: 6
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
                    font.family: Theme.monoFontFamily
                    font.pixelSize: Theme.fontSizeMedium
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
            rowSpacing: 2
            columnSpacing: Theme.spacingPanel

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

        // Cyclic interval — only visible when cyclic mode is on
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingTight
            visible: root.cyclicSend

            Label {
                text: qsTr("Interval (ms)")
                color: Theme.text
                font.pixelSize: Theme.fontSizeMedium
                font.family: Theme.fontFamily
            }
            TextField {
                id: intervalField
                Layout.fillWidth: true
                text: String(root.cyclicInterval)
                font.family: Theme.monoFontFamily
                font.pixelSize: Theme.fontSizeMedium
                horizontalAlignment: Text.AlignRight
                validator: IntValidator { bottom: 10; top: 60000 }
                background: Rectangle {
                    radius: 4
                    color: Theme.inputBg
                    border.color: parent.activeFocus ? Theme.accent : Theme.border
                    border.width: 1
                }
                onEditingFinished: {
                    var v = parseInt(text)
                    if (!isNaN(v) && v >= 10 && v <= 60000)
                        root.cyclicInterval = v
                    else
                        text = String(root.cyclicInterval)
                }
            }
        }

        Button {
            text: qsTr("Send")
            highlighted: true
            Layout.fillWidth: true
            font.family: Theme.fontFamily
            onClicked: root.send()
        }
    }

    Timer {
        id: cyclicTimer
        interval: root.cyclicInterval
        repeat: true
        running: root.cyclicSend && SerialPort.isOpen
        onTriggered: root.send()
    }
}
