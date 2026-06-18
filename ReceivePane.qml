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

    function append(rawData, length) {
        ReceiveModel.append(rawData, length)
    }

    function clear() {
        ReceiveModel.clear()
        root.clearRequested()
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
                    onClicked: {
                        receiveList.pendingAutoScroll = true
                        uiUpdateTimer.restart()
                        ReceiveModel.hexMode = !ReceiveModel.hexMode
                    }
                }

                Button {
                    text: qsTr("TS")
                    flat: true
                    highlighted: ReceiveModel.showTimestamp
                    implicitWidth: Math.min(implicitContentWidth + 16, 50)
                    onClicked: {
                        receiveList.pendingAutoScroll = true
                        uiUpdateTimer.restart()
                        ReceiveModel.showTimestamp = !ReceiveModel.showTimestamp
                    }
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

            ListView {
                id: receiveList
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                anchors.topMargin: 4
                anchors.bottomMargin: 9   // leave room for flash bar
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 800          // pre-render ~60 lines above/below viewport
                displayMarginBeginning: 400
                displayMarginEnd: 400

                // Horizontal scroll for no-wrap mode
                contentWidth: root.autoWrap ? -1 : Math.max(width, maxDelegateWidth)
                property real maxDelegateWidth: 0

                // Auto-scroll state
                property bool autoScroll: true
                property bool pendingAutoScroll: false

                function doAutoScroll() {
                    if (!pendingAutoScroll || !autoScroll)
                        return
                    pendingAutoScroll = false
                    if (contentHeight > height)
                        positionViewAtEnd()
                }

                // Auto-scroll triggers
                onContentHeightChanged: doAutoScroll()

                onContentYChanged: {
                    var maxY = Math.max(0, contentHeight - height)
                    autoScroll = (contentY >= maxY - 30)
                    // User scrolled back to bottom after pending data
                    if (autoScroll && pendingAutoScroll)
                        doAutoScroll()
                }

                model: ReceiveModel

                delegate: TextEdit {
                    id: lineDelegate
                    text: model.display
                    font.family: "Consolas"
                    font.pixelSize: 13
                    color: themePalette.text
                    readOnly: true
                    selectByMouse: true
                    persistentSelection: true
                    wrapMode: root.autoWrap ? TextEdit.Wrap : TextEdit.NoWrap
                    width: root.autoWrap ? receiveList.width
                                         : Math.max(receiveList.width, implicitWidth)
                    height: implicitHeight
                    background: null
                    padding: 0

                    onImplicitWidthChanged: {
                        if (!root.autoWrap && implicitWidth > receiveList.maxDelegateWidth) {
                            receiveList.maxDelegateWidth = implicitWidth
                        }
                    }
                }

                // Right-click context menu
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.RightButton
                    onClicked: (mouse) => {
                        // indexAt expects content coordinates
                        var idx = receiveList.indexAt(
                            mouse.x + receiveList.contentX,
                            mouse.y + receiveList.contentY)
                        if (idx >= 0) {
                            receiveList.currentIndex = idx
                        }
                        receiveContextMenu.popup(
                            mouse.x + receiveList.x + 8,
                            mouse.y + receiveList.y + 8)
                    }
                }

                ScrollBar.vertical: CustomScrollBar {
                    themePalette: root.themePalette
                    orientation: Qt.Vertical
                    policy: receiveList.contentHeight > receiveList.height + 5
                            ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }

                ScrollBar.horizontal: CustomScrollBar {
                    themePalette: root.themePalette
                    orientation: Qt.Horizontal
                    policy: receiveList.contentWidth > receiveList.width + 5
                            ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }

            // New-data indicator flash at the bottom edge
            Rectangle {
                id: newDataFlash
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                anchors.bottomMargin: 2
                height: 4
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
            text: qsTr("Copy Line")
            enabled: receiveList.currentIndex >= 0
            onTriggered: {
                var text = ReceiveModel.lineAt(receiveList.currentIndex)
                if (text) {
                    clipboardHelper.text = text
                    clipboardHelper.selectAll()
                    clipboardHelper.copy()
                }
            }
        }
        MenuItem {
            text: qsTr("Copy All")
            onTriggered: {
                clipboardHelper.text = ReceiveModel.allText()
                clipboardHelper.selectAll()
                clipboardHelper.copy()
            }
        }
        MenuSeparator {}
        MenuItem {
            text: qsTr("Clear")
            onTriggered: root.clear()
        }
    }

    // Hidden proxy for clipboard operations (Qt Quick has no direct Clipboard API)
    TextEdit {
        id: clipboardHelper
        visible: false
        width: 0
        height: 0
    }

    property bool autoWrap: true

    // Timer acts as a fallback and drives the flash animation.
    // Primary scroll trigger is receiveList.onContentHeightChanged.
    Timer {
        id: uiUpdateTimer
        interval: 80
        repeat: false
        onTriggered: {
            newDataFlashAnim.start()
            receiveList.doAutoScroll()
        }
    }

    Connections {
        target: ReceiveModel
        function onAppended(length) {
            receiveList.pendingAutoScroll = true
            uiUpdateTimer.restart()
        }
    }

    SequentialAnimation {
        id: newDataFlashAnim
        NumberAnimation { target: newDataFlash; property: "opacity"; to: 0.8; duration: 80 }
        NumberAnimation { target: newDataFlash; property: "opacity"; to: 0; duration: 400 }
    }
}
