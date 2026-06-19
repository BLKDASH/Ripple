import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import Ripple.AppSettings
import Ripple.Serial
import Ripple.I18n
import Ripple.Receive
import Ripple.Theme
import Ripple.NotificationManager

ApplicationWindow {
    id: root
    width: 1000
    height: 700
    minimumWidth: 800
    font.family: Theme.fontFamily
    minimumHeight: 600
    visible: true
    title: qsTr("Ripple")

    property bool showQuickSend: false

    // Solid fill under everything so the FluentWinUI3 background stays consistent.
    Rectangle {
        anchors.fill: parent
        z: -1
        color: Theme.darkTheme ? "#101010" : "#FFFFFF"
    }

    // Debounce saving window geometry so we don't hammer the settings file
    // during live resize.
    Timer {
        id: saveGeometryTimer
        interval: 500
        repeat: false
        onTriggered: {
            AppSettings.windowWidth = root.width
            AppSettings.windowHeight = root.height
        }
    }

    Component.onCompleted: {
        // Restore last window size (defaults to 1000×700 if not saved).
        var w = AppSettings.windowWidth
        var h = AppSettings.windowHeight
        if (w > 0) root.width = Math.max(w, root.minimumWidth)
        if (h > 0) root.height = Math.max(h, root.minimumHeight)

        Theme.darkTheme = AppSettings.darkTheme
        root.showQuickSend = AppSettings.showQuickSend

        SerialPort.errorOccurred.connect(function(msg) {
            NotificationManager.error(msg)
        })

        Translator.setCurrentLanguage(AppSettings.language)
        SerialPort.autoLogEnabled = AppSettings.autoLogEnabled
        SerialPort.autoLogFolder = AppSettings.autoLogFolder
    }

    onWidthChanged: {
        saveGeometryTimer.restart()
        if (qsDocked && quickSendLoader.item) quickSendLoader.item.x = x + width + qsOffsetX
    }
    onHeightChanged: {
        saveGeometryTimer.restart()
        if (qsDocked && quickSendLoader.item) quickSendLoader.item.height = height
    }

    Connections {
        target: Theme
        function onDarkThemeChanged() {
            AppSettings.darkTheme = Theme.darkTheme
        }
    }

    onShowQuickSendChanged: AppSettings.showQuickSend = showQuickSend

    // ── Top menu bar ───────────────────────────────────────────
    menuBar: MenuBar {
        spacing: 8
        background: Rectangle { color: Theme.panelBg }
        delegate: MenuBarItem { }

        Menu {
            title: qsTr("Ripple")
            MenuItem {
                text: qsTr("Settings")
                onTriggered: {
                    settingsDialog.loadSettings()
                    settingsDialog.toggle()
                }
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Help")
                onTriggered: helpDialog.open()
            }
            MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }

        Menu {
            title: qsTr("Port")
            MenuItem {
                text: qsTr("Refresh Ports")
                onTriggered: serialPortPanel.refreshPorts()
            }
            MenuSeparator {}
            MenuItem {
                text: SerialPort.isOpen ? qsTr("Disconnect") : qsTr("Connect")
                onTriggered: SerialPort.isOpen ? SerialPort.closePort() : SerialPort.openPort()
            }
        }

        Menu {
            title: qsTr("Receive Area")
            MenuItem {
                text: qsTr("Clear")
                onTriggered: {
                    receivePane.clear()
                    rxCount = 0
                }
            }
            MenuItem {
                text: qsTr("Copy All")
                onTriggered: receivePane.copyAll()
            }
            MenuItem {
                text: SerialPort.recordingEnabled ? qsTr("Stop Recording") : qsTr("Record")
                onTriggered: SerialPort.recordingEnabled ? SerialPort.stopRecording() : recordFileDialog.open()
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("HEX")
                checkable: true
                checked: ReceiveModel.hexMode
                onTriggered: ReceiveModel.hexMode = !ReceiveModel.hexMode
            }
            MenuItem {
                text: qsTr("Show Timestamp")
                checkable: true
                checked: ReceiveModel.showTimestamp
                onTriggered: ReceiveModel.showTimestamp = !ReceiveModel.showTimestamp
            }
            MenuItem {
                text: qsTr("Wrap")
                checkable: true
                checked: receivePane.autoWrap
                onTriggered: receivePane.autoWrap = !receivePane.autoWrap
            }
        }

        Menu {
            title: qsTr("Send Area")
            MenuItem {
                text: qsTr("Send")
                onTriggered: sendPane.send()
            }
            MenuItem {
                text: qsTr("Load to Send")
                onTriggered: loadFileDialog.open()
            }
            MenuItem {
                text: qsTr("Clear Input")
                onTriggered: sendPane.clearInput()
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("HEX")
                checkable: true
                checked: sendPane.hexMode
                onTriggered: sendPane.hexMode = !sendPane.hexMode
            }
            MenuItem {
                text: qsTr("Append \\r")
                checkable: true
                checked: sendPane.appendCr
                onTriggered: sendPane.appendCr = !sendPane.appendCr
            }
            MenuItem {
                text: qsTr("Append \\n")
                checkable: true
                checked: sendPane.appendLf
                onTriggered: sendPane.appendLf = !sendPane.appendLf
            }
            MenuItem {
                text: qsTr("Cyclic")
                checkable: true
                checked: sendPane.cyclicSend
                onTriggered: sendPane.cyclicSend = !sendPane.cyclicSend
            }
            MenuSeparator {}
            MenuItem {
                text: qsTr("Show quick send window")
                checkable: true
                checked: root.showQuickSend
                onTriggered: root.showQuickSend = !root.showQuickSend
            }
        }
    }

    // ── Global shortcuts ───────────────────────────────────────
    Shortcut {
        sequences: [StandardKey.Quit]
        onActivated: Qt.quit()
    }
    Shortcut {
        sequences: ["Ctrl+Enter"]
        onActivated: sendPane.send()
    }

    // ── Main content area ──────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Left: serial port config panel (full height)
        SerialPortPanel {
            id: serialPortPanel
            Layout.preferredWidth: 200
            Layout.fillHeight: true
        }

        // Center: receive + send
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            // Receive area
            ReceivePane {
                id: receivePane
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 200
                onClearRequested: { rxCount = 0 }
            }

            // Send area
            SendPane {
                id: sendPane
                Layout.fillWidth: true
                Layout.preferredHeight: 240
            }
        }

    }

    // ── Bottom status bar ──────────────────────────────────────
    footer: StatusBar {
        rxCount: root.rxCount
        txCount: root.txCount
    }

    Connections {
        target: SerialPort
        function onBytesReceived(count) { rxCount += count }
        function onBytesSent(count) { txCount += count }
    }

    property int rxCount: 0
    property int txCount: 0

    // ── Settings panel (slides in from left) ──────────────────
    SettingsDialog {
        id: settingsDialog
        appWindow: root
    }

    HelpDialog {
        id: helpDialog

        onAboutToShow: {
            x = (root.width - width) / 2
            y = (root.height - height) / 2
        }
    }

    // ── Quick Send floating window (dynamically created) ───────
    property bool qsDocked: false
    property real qsOffsetX: 5
    property real qsOffsetY: 0

    // Follow main window when docked
    onXChanged: { if (qsDocked && quickSendLoader.item) quickSendLoader.item.x = x + width + qsOffsetX }
    onYChanged: { if (qsDocked && quickSendLoader.item) quickSendLoader.item.y = y + qsOffsetY }

    Timer {
        id: qsDockCheckTimer
        interval: 200
        repeat: false
        onTriggered: {
            if (!quickSendLoader.item) return
            var win = quickSendLoader.item
            var expectedX = root.x + root.width + qsOffsetX
            var expectedY = root.y + qsOffsetY
            var dist = Math.abs(win.x - expectedX) + Math.abs(win.y - expectedY)
            if (dist < 30) {
                // Snap to dock position
                qsDocked = true
                win.x = expectedX
                win.y = expectedY
            } else {
                qsDocked = false
            }
        }
    }

    Loader {
        id: quickSendLoader
        active: root.showQuickSend
        sourceComponent: QuickSendGrid {
            Component.onCompleted: {
                height = root.height
                x = root.x + root.width + 5
                y = root.y
                qsDocked = true
            }
            onXChanged: qsDockCheckTimer.restart()
            onYChanged: qsDockCheckTimer.restart()
            onClosedByUser: {
                qsDocked = false
                root.showQuickSend = false
            }
        }
    }

    // ── Notifications ──────────────────────────────────────────
    NotifyOverlay { id: notify }

    // ── File dialogs ───────────────────────────────────────────
    FileDialog {
        id: recordFileDialog
        title: qsTr("Select recording file")
        fileMode: FileDialog.SaveFile
        nameFilters: ["Log files (*.log)", "Text files (*.txt)", "Binary files (*.bin)", "All files (*)"]
        onAccepted: {
            var path = selectedFile.toString().replace(/^file:\/\/+/, "")
            if (SerialPort.wouldRecordingConflict(path)) {
                NotificationManager.error(qsTr("Recording file conflicts with the auto-log file"))
                return
            }
            SerialPort.startRecording(path)
        }
    }

    FileDialog {
        id: loadFileDialog
        title: qsTr("Load file to send")
        fileMode: FileDialog.OpenFile
        nameFilters: ["Text files (*.txt)", "Binary files (*.bin)", "All files (*)"]
        onAccepted: {
            var path = selectedFile.toString().replace(/^file:\/\/+/, "")
            if (path.endsWith(".bin")) {
                var hex = SerialPort.readFileAsHex(path)
                sendPane.setContent(hex, true)
            } else {
                var text = SerialPort.readFile(path)
                sendPane.setContent(text, false)
            }
        }
    }
}
