import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Ripple.AppSettings
import Ripple.Serial
import Ripple.Theme
import Ripple.NotificationManager

MainPanel {
    id: root

    property int itemCount: 6
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingPanel
        spacing: Theme.spacingSection

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.spacingTight

            Label {
                text: qsTr("Quick Send")
                font.bold: true
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Button {
                text: qsTr("Load")
                flat: true
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                onClicked: loadDialog.open()
            }
            Button {
                text: qsTr("Save")
                flat: true
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSize
                onClicked: saveDialog.open()
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: quickModel
            ScrollBar.vertical: CustomScrollBar { orientation: Qt.Vertical }

            delegate: Rectangle {
                id: delegateRoot
                width: listView.width
                height: delegateLayout.implicitHeight + 8
                radius: Theme.radiusInput
                color: delegateMouse.containsMouse
                       ? Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                       : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.02)
                border.color: Theme.border
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: delegateMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                RowLayout {
                    id: delegateLayout
                    anchors.fill: parent
                    anchors.margins: 4
                    spacing: Theme.spacingTight

                    // Row number indicator
                    Label {
                        text: index + 1
                        color: Theme.text
                        opacity: 0.4
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.monoFontFamily
                        Layout.preferredWidth: 16
                        horizontalAlignment: Text.AlignRight
                    }

                    TextField {
                        Layout.fillWidth: true
                        text: model.command
                        placeholderText: qsTr("Command") + " " + (index + 1)
                        color: Theme.text
                        font.family: Theme.monoFontFamily
                        font.pixelSize: Theme.fontSize
                        background: Rectangle {
                            radius: 4
                            color: Theme.inputBg
                            border.color: parent.activeFocus ? Theme.accent : Theme.border
                            border.width: 1
                        }
                        onTextChanged: {
                            if (model.command !== text) {
                                quickModel.setProperty(index, "command", text)
                                saveToSettings()
                            }
                        }
                    }

                    CheckBox {
                        text: "HEX"
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        indicator.width: 16
                        indicator.height: 16
                        checked: model.hex
                        onCheckedChanged: {
                            if (model.hex !== checked) {
                                quickModel.setProperty(index, "hex", checked)
                                saveToSettings()
                            }
                        }
                    }

                    Button {
                        text: qsTr("Send")
                        highlighted: true
                        enabled: SerialPort.isOpen
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        onClicked: sendItem(quickModel.get(index))
                    }
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
        onAccepted: saveConfig(selectedFile.toString().replace(/^file:\/\/+/, ""))
    }

    FileDialog {
        id: loadDialog
        title: qsTr("Load quick send config")
        fileMode: FileDialog.OpenFile
        nameFilters: ["JSON files (*.json)", "All files (*)"]
        onAccepted: loadConfig(selectedFile.toString().replace(/^file:\/\/+/, ""))
    }

    Component.onCompleted: restoreFromSettings()

    function initDefault() {
        quickModel.clear()
        for (var i = 0; i < root.itemCount; ++i) {
            quickModel.append({ command: "", hex: false })
        }
    }

    function saveToSettings() {
        var items = []
        for (var i = 0; i < quickModel.count; ++i) {
            var item = quickModel.get(i)
            items.push({ command: item.command, hex: item.hex })
        }
        AppSettings.quickSendJson = JSON.stringify(items)
    }

    function restoreFromSettings() {
        var json = AppSettings.quickSendJson
        if (!json) {
            initDefault()
            return
        }
        try {
            var items = JSON.parse(json)
            quickModel.clear()
            for (var i = 0; i < root.itemCount; ++i) {
                if (i < items.length) {
                    quickModel.append(items[i])
                } else {
                    quickModel.append({ command: "", hex: false })
                }
            }
        } catch (e) {
            initDefault()
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
            NotificationManager.error(qsTr("Failed to save config"))
        }
    }

    function loadConfig(filePath) {
        var json = SerialPort.readFile(filePath)
        if (json.length === 0) {
            NotificationManager.error(qsTr("Failed to load config"))
            return
        }
        try {
            var items = JSON.parse(json)
            quickModel.clear()
            for (var i = 0; i < root.itemCount; ++i) {
                if (i < items.length) {
                    quickModel.append(items[i])
                } else {
                    quickModel.append({ command: "", hex: false })
                }
            }
        } catch (e) {
            NotificationManager.error(qsTr("Invalid config file"))
        }
    }
}
