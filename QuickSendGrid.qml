import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import CWY.Serial

Rectangle {
    id: root
    color: _panelBg
    border.color: _border
    radius: 4

    property int itemCount: 6

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Label {
                text: qsTr("Quick Send")
                font.bold: true
                color: _text
            }
            Item { Layout.fillWidth: true }
            Button {
                text: qsTr("Load")
                flat: true
                onClicked: loadDialog.open()
            }
            Button {
                text: qsTr("Save")
                flat: true
                onClicked: saveDialog.open()
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 6
            model: quickModel
            ScrollBar.vertical: ScrollBar {}

            delegate: RowLayout {
                width: listView.width
                spacing: 6

                TextField {
                    Layout.fillWidth: true
                    text: model.command
                    placeholderText: qsTr("Command") + " " + (index + 1)
                    color: _text
                    font.family: "Consolas"
                    font.pixelSize: 12
                    background: Rectangle {
                        color: _inputBg
                        border.color: _border
                        radius: 4
                    }
                    onTextChanged: quickModel.set(index, { "command": text })
                }

                CheckBox {
                    text: qsTr("HEX")
                    checked: model.hex
                    onCheckedChanged: quickModel.set(index, { "hex": checked })
                }

                Button {
                    text: qsTr("Send")
                    enabled: SerialPort.isOpen
                    onClicked: sendItem(quickModel.get(index))
                }
            }
        }
    }

    ListModel { id: quickModel }

    FileDialog {
        id: saveDialog
        title: qsTr("Save quick send config")
        fileMode: FileDialog.SaveFile
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        onAccepted: saveConfig(selectedFile.toString().replace(/^file:\/+/, ""))
    }

    FileDialog {
        id: loadDialog
        title: qsTr("Load quick send config")
        fileMode: FileDialog.OpenFile
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        onAccepted: loadConfig(selectedFile.toString().replace(/^file:\/+/, ""))
    }

    Component.onCompleted: initDefault()

    function initDefault() {
        quickModel.clear()
        for (var i = 0; i < root.itemCount; ++i) {
            quickModel.append({ command: "", hex: false })
        }
    }

    function sendItem(item) {
        if (!SerialPort.isOpen || !item.command) return
        if (item.hex) {
            SerialPort.sendHex(item.command)
        } else {
            SerialPort.sendText(item.command)
        }
    }

    function saveConfig(filePath) {
        var items = []
        for (var i = 0; i < quickModel.count; ++i) {
            var item = quickModel.get(i)
            items.push({
                command: item.command,
                hex: item.hex
            })
        }
        var json = JSON.stringify(items, null, 2)
        if (!SerialPort.writeFile(filePath, json)) {
            notify.error(qsTr("Failed to save config"))
        }
    }

    function loadConfig(filePath) {
        var json = SerialPort.readFile(filePath)
        if (json.length === 0) {
            notify.error(qsTr("Failed to load config"))
            return
        }
        try {
            var items = JSON.parse(json)
            quickModel.clear()
            for (var i = 0; i < Math.max(items.length, root.itemCount); ++i) {
                if (i < items.length) {
                    quickModel.append(items[i])
                } else {
                    quickModel.append({ command: "", hex: false })
                }
            }
        } catch (e) {
            notify.error(qsTr("Invalid config file"))
        }
    }
}
