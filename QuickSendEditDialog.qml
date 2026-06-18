import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.Serial

Dialog {
    id: root
    title: qsTr("Edit Quick Send")
    standardButtons: Dialog.Save | Dialog.Cancel
    modal: true

    property var item

    signal saved(var item)

    width: 360
    height: 320

    ColumnLayout {
        anchors.fill: parent
        spacing: 12

        Label {
            text: qsTr("Button Name")
            color: _text
        }
        TextField {
            id: nameField
            Layout.fillWidth: true
            text: root.item ? root.item.name : ""
            color: _text
            background: Rectangle {
                color: _inputBg
                border.color: _border
                radius: 4
            }
        }

        Label {
            text: qsTr("Send Content")
            color: _text
        }
        TextArea {
            id: contentField
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: root.item ? root.item.content : ""
            color: _text
            font.family: "Consolas"
            background: Rectangle {
                color: _inputBg
                border.color: _border
                radius: 4
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            CheckBox {
                id: hexCheck
                text: qsTr("HEX")
                checked: root.item ? root.item.hex : false
            }
            CheckBox {
                id: lfCheck
                text: qsTr("Append \\n")
                checked: root.item ? root.item.appendLf : false
            }
        }
    }

    onAccepted: {
        root.saved({
            name: nameField.text,
            content: contentField.text,
            hex: hexCheck.checked,
            appendLf: lfCheck.checked
        })
    }
}
