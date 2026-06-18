import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.Serial
import CWY.Theme

Dialog {
    id: root
    title: qsTr("Edit Quick Send")
    font.family: Theme.fontFamily
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
            color: Theme.text
        }
        TextField {
            id: nameField
            Layout.fillWidth: true
            text: root.item ? root.item.name : ""
            color: Theme.text
        }

        Label {
            text: qsTr("Send Content")
            color: Theme.text
        }
        TextArea {
            id: contentField
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: root.item ? root.item.content : ""
            color: Theme.text
            font.family: Theme.monoFontFamily
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
