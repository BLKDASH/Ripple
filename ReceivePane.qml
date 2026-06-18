import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.Serial
import CWY.Receive

Rectangle {
    id: root
    color: _panelBg
    border.color: _border
    radius: 4

    signal saveRequested()
    signal clearRequested()

    function append(rawData, length) {
        ReceiveModel.append(rawData, length)
    }

    function clear() {
        ReceiveModel.clear()
        receiveList.autoScroll = true
        receiveList.pendingAutoScroll = false
        root.clearRequested()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // ── Toolbar ──────────────────────────────────────────
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
                    color: _text
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

        // ── Receive text area ────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: _inputBg
            border.color: _border
            radius: 4
            clip: true

            ListView {
                id: receiveList
                anchors.fill: parent
                anchors.leftMargin: 4
                anchors.rightMargin: 4
                anchors.topMargin: 4
                anchors.bottomMargin: 9
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 800
                displayMarginBeginning: 400
                displayMarginEnd: 400

                contentWidth: root.autoWrap ? -1 : Math.max(width, maxDelegateWidth)
                property real maxDelegateWidth: 0

                // ── Auto-scroll ──────────────────────────────
                property bool autoScroll: true
                property bool pendingAutoScroll: false
                property real prevContentY: 0

                function doAutoScroll() {
                    if (!pendingAutoScroll || !autoScroll)
                        return
                    pendingAutoScroll = false
                    if (contentHeight > height)
                        positionViewAtEnd()
                }

                onContentHeightChanged: doAutoScroll()

                onContentYChanged: {
                    // Any upward scroll (even 1px) stops auto-scroll.
                    // positionViewAtEnd() always scrolls down, so a
                    // decreasing contentY can only be user-initiated.
                    if (contentHeight <= height) {
                        autoScroll = true
                    } else if (contentY < prevContentY) {
                        autoScroll = false
                    }

                    // User scrolled to the very bottom — re-enable.
                    // atYEnd handles variable-height delegates (wrapped
                    // lines) correctly, unlike a fixed pixel threshold.
                    if (atYEnd)
                        autoScroll = true

                    prevContentY = contentY

                    if (autoScroll && pendingAutoScroll)
                        doAutoScroll()
                }

                // ── Cross-line selection ─────────────────────
                property int selStartRow: -1
                property int selStartCol: -1
                property int selEndRow: -1
                property int selEndCol: -1
                property int selVersion: 0          // bumps on every change
                property bool selecting: false

                function clearSelection() {
                    selStartRow = -1; selStartCol = -1
                    selEndRow   = -1; selEndCol   = -1
                    selecting = false
                    selVersion++
                }

                function hasSelection() {
                    return selStartRow >= 0 && selEndRow >= 0 &&
                           (selStartRow !== selEndRow || selStartCol !== selEndCol)
                }

                // Normalized (start <= end)
                function normSel() {
                    if (selStartRow < 0 || selEndRow < 0)
                        return null
                    var sr = selStartRow, sc = selStartCol
                    var er = selEndRow,   ec = selEndCol
                    if (sr > er || (sr === er && sc > ec)) {
                        return { sr: er, sc: ec, er: sr, ec: sc }
                    }
                    return { sr: sr, sc: sc, er: er, ec: ec }
                }

                function getSelectedText() {
                    var ns = normSel()
                    if (!ns) return ""
                    var lines = []
                    for (var i = ns.sr; i <= ns.er; i++) {
                        var line = ReceiveModel.lineAt(i)
                        if (i === ns.sr && i === ns.er)
                            lines.push(line.substring(ns.sc, ns.ec))
                        else if (i === ns.sr)
                            lines.push(line.substring(ns.sc))
                        else if (i === ns.er)
                            lines.push(line.substring(0, ns.ec))
                        else
                            lines.push(line)
                    }
                    return lines.join('\n')
                }

                function copySelection() {
                    var t = getSelectedText()
                    if (t) {
                        clipboardHelper.text = t
                        clipboardHelper.selectAll()
                        clipboardHelper.copy()
                        return true
                    }
                    return false
                }

                // Iterate instantiated delegates and refresh their selection
                function refreshDelegates() {
                    var kids = contentItem.children
                    for (var i = 0; i < kids.length; i++) {
                        var child = kids[i]
                        if (child && typeof child.applySelection === 'function')
                            child.applySelection()
                    }
                }

                // ── Unified mouse handler ────────────────────
                MouseArea {
                    id: selMouse
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton

                    // Keep track so we don't scroll while selecting
                    preventStealing: true
                    property bool isDragging: false
                    property real dragStartX: 0
                    property real dragStartY: 0

                    function contentPos(mouse) {
                        return {
                            x: mouse.x + receiveList.contentX,
                            y: mouse.y + receiveList.contentY
                        }
                    }

                    function delegateAt(cx, cy) {
                        var row = receiveList.indexAt(cx, cy)
                        if (row < 0) return null
                        // Search through instantiated delegates for the one at (cx,cy)
                        var kids = receiveList.contentItem.children
                        for (var i = 0; i < kids.length; i++) {
                            var child = kids[i]
                            if (child && typeof child._inSelection !== 'undefined' &&
                                child.x <= cx && cx <= child.x + child.width &&
                                child.y <= cy && cy <= child.y + child.height) {
                                return { row: row,
                                         localX: cx - child.x, localY: cy - child.y }
                            }
                        }
                        return null
                    }

                    onPressed: (mouse) => {
                        if (mouse.button === Qt.RightButton) {
                            // Right click — show context menu
                            var cp = contentPos(mouse)
                            var idx = receiveList.indexAt(cp.x, cp.y)
                            if (idx >= 0)
                                receiveList.currentIndex = idx
                            receiveContextMenu.popup(
                                mouse.x + receiveList.x + 8,
                                mouse.y + receiveList.y + 8)
                            mouse.accepted = true
                            return
                        }

                        // Left button — start selection
                        isDragging = false
                        dragStartX = mouse.x
                        dragStartY = mouse.y

                        var cp = contentPos(mouse)
                        var d = delegateAt(cp.x, cp.y)
                        if (!d) {
                            receiveList.clearSelection()
                            // Let ListView handle flick
                            mouse.accepted = false
                            return
                        }
                        var col = Math.round(d.localX / charMetrics.advanceWidth)

                        receiveList.selStartRow = d.row
                        receiveList.selStartCol = col
                        receiveList.selEndRow   = d.row
                        receiveList.selEndCol   = col
                        receiveList.selecting   = true
                        receiveList.selVersion++
                        mouse.accepted = true
                    }

                    onPositionChanged: (mouse) => {
                        if (!receiveList.selecting) {
                            mouse.accepted = false
                            return
                        }
                        var dx = mouse.x - dragStartX
                        var dy = mouse.y - dragStartY
                        if (!isDragging && Math.abs(dx) < 4 && Math.abs(dy) < 4)
                            return  // tiny move, ignore
                        isDragging = true

                        var cp = contentPos(mouse)
                        var d = delegateAt(cp.x, cp.y)
                        if (!d) return

                        var col = Math.round(d.localX / charMetrics.advanceWidth)

                        if (receiveList.selEndRow !== d.row ||
                            receiveList.selEndCol !== col) {
                            receiveList.selEndRow = d.row
                            receiveList.selEndCol = col
                            receiveList.selVersion++
                        }
                        mouse.accepted = true
                    }

                    onReleased: (mouse) => {
                        if (!receiveList.selecting) {
                            mouse.accepted = false
                            return
                        }
                        receiveList.selecting = false
                        receiveList.selVersion++  // final refresh
                        // If just a click (no drag), clear selection
                        if (!isDragging)
                            receiveList.clearSelection()
                        isDragging = false
                        mouse.accepted = true
                    }
                }

                // ── Font metrics for column calculation ──────
                TextMetrics {
                    id: charMetrics
                    font.family: "Consolas"
                    font.pixelSize: 13
                    text: "X"
                }

                // ── Delegate ─────────────────────────────────
                model: ReceiveModel

                delegate: Rectangle {
                    id: lineWrapper
                    width: root.autoWrap ? receiveList.width
                                         : Math.max(receiveList.width, lineText.implicitWidth)
                    height: lineText.implicitHeight
                    color: "transparent"

                    // Normalized selection bounds
                    property real _cw: charMetrics.advanceWidth
                    property int _nsr: {
                        var sv = receiveList.selStartRow, ev = receiveList.selEndRow
                        return (sv < 0 || ev < 0) ? -1 : Math.min(sv, ev)
                    }
                    property int _ner: {
                        var sv = receiveList.selStartRow, ev = receiveList.selEndRow
                        return (sv < 0 || ev < 0) ? -1 : Math.max(sv, ev)
                    }
                    property int _nsc: {
                        var sv = receiveList.selStartRow, ev = receiveList.selEndRow
                        if (sv < 0 || ev < 0) return 0
                        return (sv < ev) ? receiveList.selStartCol :
                               (sv > ev) ? receiveList.selEndCol :
                               Math.min(receiveList.selStartCol, receiveList.selEndCol)
                    }
                    property int _nec: {
                        var sv = receiveList.selStartRow, ev = receiveList.selEndRow
                        if (sv < 0 || ev < 0) return 0
                        return (sv < ev) ? receiveList.selEndCol :
                               (sv > ev) ? receiveList.selStartCol :
                               Math.max(receiveList.selStartCol, receiveList.selEndCol)
                    }
                    property bool _inSelection: _nsr >= 0 && index >= _nsr && index <= _ner

                    // Precise selection highlight
                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        x: (lineWrapper._inSelection && index === lineWrapper._nsr)
                           ? lineWrapper._nsc * lineWrapper._cw : 0
                        width: {
                            if (!lineWrapper._inSelection) return 0
                            if (index === lineWrapper._nsr && index === lineWrapper._ner)
                                return (lineWrapper._nec - lineWrapper._nsc) * lineWrapper._cw
                            if (index === lineWrapper._nsr)
                                return parent.width - (lineWrapper._nsc * lineWrapper._cw)
                            if (index === lineWrapper._ner)
                                return lineWrapper._nec * lineWrapper._cw
                            return parent.width  // full row
                        }
                        color: _accent
                        opacity: 0.25
                    }

                    Text {
                        id: lineText
                        text: model.display
                        font.family: "Consolas"
                        font.pixelSize: 13
                        color: _text
                        textFormat: Text.PlainText
                        width: root.autoWrap ? parent.width : undefined
                        wrapMode: root.autoWrap ? Text.Wrap : Text.NoWrap
                        renderType: Text.NativeRendering

                        onImplicitWidthChanged: {
                            if (!root.autoWrap && implicitWidth > receiveList.maxDelegateWidth)
                                receiveList.maxDelegateWidth = implicitWidth
                        }
                    }
                }

                ScrollBar.vertical: CustomScrollBar {
                    orientation: Qt.Vertical
                    policy: receiveList.contentHeight > receiveList.height + 5
                            ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }

                ScrollBar.horizontal: CustomScrollBar {
                    orientation: Qt.Horizontal
                    policy: receiveList.contentWidth > receiveList.width + 5
                            ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                }
            }

            // New-data indicator flash
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
                color: _accent
                opacity: 0
                enabled: false
            }
        }
    }

    // ── Context menu ────────────────────────────────────────
    Menu {
        id: receiveContextMenu
        MenuItem {
            text: qsTr("Copy")
            enabled: receiveList.hasSelection() || receiveList.currentIndex >= 0
            onTriggered: {
                if (!receiveList.copySelection()) {
                    // fallback: copy current line
                    var t = ReceiveModel.lineAt(receiveList.currentIndex)
                    if (t) {
                        clipboardHelper.text = t
                        clipboardHelper.selectAll()
                        clipboardHelper.copy()
                    }
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

    // Hidden proxy for clipboard
    TextEdit {
        id: clipboardHelper
        visible: false
        width: 0
        height: 0
    }

    // ── Keyboard shortcut ───────────────────────────────────
    Shortcut {
        sequences: [StandardKey.Copy]
        onActivated: {
            if (!receiveList.copySelection()) {
                var t = ReceiveModel.lineAt(receiveList.currentIndex)
                if (t) {
                    clipboardHelper.text = t
                    clipboardHelper.selectAll()
                    clipboardHelper.copy()
                }
            }
        }
    }

    property bool autoWrap: true

    // Timer: fallback auto-scroll + flash animation
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
