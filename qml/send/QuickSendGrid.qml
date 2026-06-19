import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Ripple.AppSettings
import Ripple.Serial
import Ripple.Theme
import Ripple.NotificationManager

Window {
    id: root
    title: qsTr("Quick Send")
    width: 420
    height: 500
    minimumWidth: 320
    minimumHeight: 200
    visible: true
    flags: Qt.Window
    color: Theme.panelBg

    property int itemCount: 15
    signal closedByUser()

    onVisibleChanged: {
        if (!visible)
            closedByUser()
    }

    // Panel border
    Rectangle {
        anchors.fill: parent
        color: "transparent"
        radius: 8
        border.color: Theme.border
        border.width: 1
    }

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
                font.family: Theme.fontFamily
                color: Theme.text
            }
            Item { Layout.fillWidth: true }
            Label {
                text: "📂"
                font.pixelSize: Theme.fontSize
                color: Theme.text
                opacity: loadMouse.containsMouse ? 1.0 : 0.6
                MouseArea {
                    id: loadMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: loadDialog.open()
                }
            }
            Label {
                text: "💾"
                font.pixelSize: Theme.fontSize
                color: Theme.text
                opacity: saveMouse.containsMouse ? 1.0 : 0.6
                MouseArea {
                    id: saveMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: saveDialog.open()
                }
            }
            Label {
                text: "🗑"
                font.pixelSize: Theme.fontSize
                color: Theme.text
                opacity: clearMouse.containsMouse ? 1.0 : 0.6
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clearAll()
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            model: quickModel
            ScrollBar.vertical: CustomScrollBar {
                orientation: Qt.Vertical
                policy: ScrollBar.AlwaysOff
            }

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
                    anchors.rightMargin: 12
                    spacing: Theme.spacingTight

                    TextField {
                        id: nameField
                        text: model.name || ""
                        placeholderText: String(index + 1)
                        placeholderTextColor: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.4)
                        color: Theme.text
                        font.pixelSize: Theme.fontSize
                        font.family: Theme.fontFamily
                        Layout.preferredWidth: 40
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle {
                            radius: 4
                            color: nameField.activeFocus ? Theme.inputBg : "transparent"
                            border.color: nameField.activeFocus ? Theme.accent : "transparent"
                            border.width: 1
                        }
                        onEditingFinished: {
                            var trimmed = text.trim()
                            if (trimmed !== model.name) {
                                quickModel.setProperty(index, "name", trimmed)
                                saveToSettings()
                            }
                        }
                    }

                    TextField {
                        Layout.fillWidth: true
                        text: model.command
                        placeholderText: qsTr("Command") + " " + (index + 1)
                        color: Theme.text
                        font.family: Theme.monoFontFamily
                        font.pixelSize: Theme.fontSizeCode
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
            quickModel.append({ name: "", command: "", hex: false })
        }
    }

    function clearAll() {
        initDefault()
        saveToSettings()
    }

    function saveToSettings() {
        var items = []
        for (var i = 0; i < quickModel.count; ++i) {
            var item = quickModel.get(i)
            items.push({ name: item.name, command: item.command, hex: item.hex })
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
                    quickModel.append({
                        name: items[i].name || "",
                        command: items[i].command || "",
                        hex: items[i].hex || false
                    })
                } else {
                    quickModel.append({ name: "", command: "", hex: false })
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
                name: item.name,
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
                    quickModel.append({
                        name: items[i].name || "",
                        command: items[i].command || "",
                        hex: items[i].hex || false
                    })
                } else {
                    quickModel.append({ name: "", command: "", hex: false })
                }
            }
        } catch (e) {
            NotificationManager.error(qsTr("Invalid config file"))
        }
    }
}
