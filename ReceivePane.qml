import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.Serial
import CWY.Receive

Rectangle {
    id: root
    color: themePalette.panel
    border.color: themePalette.border
    radius: 4

    property var themePalette

    signal saveRequested()
    signal clearRequested()

    function append(textData, hexData, length) {
        ReceiveModel.append(textData, hexData, length)
    }

    function clear() {
        ReceiveModel.clear()
        root.clearRequested()
    }

    Component.onCompleted: {
        ReceiveModel.setTextDocument(receiveEdit.textDocument)
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // Toolbar
        Flickable {
            Layout.fillWidth: true
            height: toolbarRow.implicitHeight
            contentWidth: toolbarRow.implicitWidth
            flickableDirection: Flickable.HorizontalFlick
            clip: true

            RowLayout {
                id: toolbarRow
                spacing: 4

                Label {
                    text: qsTr("Receive")
                    font.bold: true
                    color: themePalette.text
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: ReceiveModel.hexMode ? qsTr("HEX") : qsTr("Text")
                    flat: true
                    implicitWidth: Math.min(implicitContentWidth + 16, 70)
                    onClicked: ReceiveModel.hexMode = !ReceiveModel.hexMode
                }

                Button {
                    text: qsTr("TS")
                    flat: true
                    highlighted: ReceiveModel.showTimestamp
                    implicitWidth: Math.min(implicitContentWidth + 16, 50)
                    onClicked: ReceiveModel.showTimestamp = !ReceiveModel.showTimestamp
                }

                Button {
                    text: qsTr("Wrap")
                    flat: true
                    highlighted: root.autoWrap
                    implicitWidth: Math.min(implicitContentWidth + 16, 60)
                    onClicked: root.autoWrap = !root.autoWrap
                }

                Button {
                    text: qsTr("Clear")
                    flat: true
                    implicitWidth: Math.min(implicitContentWidth + 16, 60)
                    onClicked: root.clear()
                }
            }
        }

        // Receive text area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: themePalette.background
            border.color: themePalette.border
            radius: 4
            clip: true

            Flickable {
                id: receiveFlickable
                anchors.fill: parent
                anchors.margins: 4
                contentWidth: root.autoWrap ? width : Math.max(width, receiveEdit.contentWidth)
                contentHeight: receiveEdit.contentHeight
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds
                clip: true
                property bool autoScroll: true
                property bool programmaticScroll: false

                onContentYChanged: {
                    if (!programmaticScroll) {
                        var maxY = Math.max(0, contentHeight - height)
                        autoScroll = (contentY >= maxY - 30)
                    }
                }

                TextArea {
                    id: receiveEdit
                    width: receiveFlickable.width
                    height: implicitHeight
                    readOnly: true
                    selectByMouse: true
                    wrapMode: root.autoWrap ? Text.Wrap : Text.NoWrap
                    color: themePalette.text
                    font.family: "Consolas"
                    font.pixelSize: 13
                    textFormat: Text.PlainText
                    background: null

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onPressed: (mouse) => {
                            if (mouse.button === Qt.RightButton) {
                                var mapped = mapToItem(root, mouse.x, mouse.y)
                                receiveContextMenu.popup(mapped.x, mapped.y)
                            }
                        }
                    }
                }

                ScrollBar.vertical: CustomScrollBar {
                    themePalette: root.themePalette
                    orientation: Qt.Vertical
                    policy: receiveFlickable.contentHeight > receiveFlickable.height + 5 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }

                ScrollBar.horizontal: CustomScrollBar {
                    themePalette: root.themePalette
                    orientation: Qt.Horizontal
                    policy: receiveFlickable.contentWidth > receiveFlickable.width + 5 ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }

            // New-data indicator flash at the bottom edge
            Rectangle {
                id: newDataFlash
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 1
                height: 5
                radius: 2
                color: themePalette.accent
                opacity: 0
                enabled: false
            }
        }
    }

    Menu {
        id: receiveContextMenu
        MenuItem {
            text: qsTr("Copy")
            enabled: receiveEdit.selectedText.length > 0
            onTriggered: receiveEdit.copy()
        }
        MenuItem {
            text: qsTr("Select All")
            onTriggered: receiveEdit.selectAll()
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Clear")
            onTriggered: root.clear()
        }
    }

    property bool autoWrap: true

    Connections {
        target: ReceiveModel
        function onAppended(length) {
            newDataFlashAnim.start()
            if (receiveFlickable.autoScroll) {
                var maxY = Math.max(0, receiveFlickable.contentHeight - receiveFlickable.height)
                receiveFlickable.programmaticScroll = true
                receiveFlickable.contentY = maxY
                receiveFlickable.programmaticScroll = false
            }
        }
    }

    SequentialAnimation {
        id: newDataFlashAnim
        NumberAnimation { target: newDataFlash; property: "opacity"; to: 0.8; duration: 80 }
        NumberAnimation { target: newDataFlash; property: "opacity"; to: 0; duration: 400 }
    }
}
