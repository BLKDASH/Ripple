import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import QtCore
import CWY.Serial
import CWY.I18n
import CWY.Receive

ApplicationWindow {
    id: root
    width: 1000
    height: 700
    minimumWidth: 800
    minimumHeight: 600
    visible: true
    title: qsTr("CWY Serial Assistant")

    // ── Theme ──────────────────────────────────────────────────
    property bool darkTheme: false

    readonly property color _panelBg:  darkTheme ? "#202020" : "#F3F3F3"
    readonly property color _inputBg:  darkTheme ? "#181818" : "#FFFFFF"
    readonly property color _border:   darkTheme ? "#383838" : "#E0E0E0"
    readonly property color _text:     darkTheme ? "#E8E8E8" : "#151515"
    readonly property color _accent:   darkTheme ? "#60CDFF" : "#005FB8"
    readonly property color _success:  "#2EA043"
    readonly property color _error:    "#F85149"
    readonly property color _warning:  "#D29922"

    // Set FluentWinUI3 window colours
    palette {
        window: _panelBg
        windowText: _text
        base: _inputBg
        text: _text
        button: _panelBg
        buttonText: _text
        highlight: _accent
        highlightedText: darkTheme ? "#000000" : "#FFFFFF"
        toolTipBase: _panelBg
        toolTipText: _text
    }

    // Leave a solid fill under everything
    Rectangle {
        anchors.fill: parent
        z: -1
        color: darkTheme ? "#101010" : "#FFFFFF"
    }

    // ── Persistent settings ────────────────────────────────────
    Settings {
        id: appSettings
        property alias darkTheme: root.darkTheme
        property alias showQuickSend: root.showQuickSend
        property string language: "zh_CN"
        property bool autoLogEnabled: false
        property string autoLogPath: ""
    }

    property bool showQuickSend: false

    Component.onCompleted: {
        SerialPort.errorOccurred.connect(function(msg) {
            notify.error(msg)
        })

        Translator.setCurrentLanguage(appSettings.language)
        SerialPort.autoLogEnabled = appSettings.autoLogEnabled
        SerialPort.autoLogPath = appSettings.autoLogPath
    }

    // ── Top toolbar ────────────────────────────────────────────
    header: ToolBar {
        height: 44
        background: Rectangle { color: _panelBg }
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            spacing: 8

            Button {
                text: SerialPort.isOpen ? qsTr("Disconnect") : qsTr("Connect")
                highlighted: true
                onClicked: SerialPort.isOpen ? SerialPort.closePort() : SerialPort.openPort()
            }

            ToolSeparator {}

            Button {
                text: qsTr("Clear")
                onClicked: {
                    receivePane.clear()
                    rxCount = 0
                }
            }

            Button {
                id: recordButton
                text: SerialPort.recordingEnabled ? qsTr("Stop Recording") : qsTr("Record")
                highlighted: SerialPort.recordingEnabled
                onClicked: {
                    if (SerialPort.recordingEnabled) {
                        SerialPort.stopRecording()
                    } else {
                        recordFileDialog.open()
                    }
                }
            }

            Button {
                text: qsTr("Load to Send")
                onClicked: loadFileDialog.open()
            }

            Item { Layout.fillWidth: true }

            Button {
                id: settingsButton
                text: qsTr("Settings")
                onClicked: settingsDialog.open()
            }

            Button {
                text: darkTheme ? "☀" : "🌙"
                onClicked: root.darkTheme = !root.darkTheme
            }
        }
    }

    // ── Main content area ──────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Left: serial port config panel
        SerialPortPanel {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
        }

        // Center: receive area
        ReceivePane {
            id: receivePane
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 200
            onClearRequested: { rxCount = 0 }
        }

        // Right: send area + quick send
        ColumnLayout {
            Layout.preferredWidth: 280
            Layout.maximumWidth: 280
            Layout.fillHeight: true
            spacing: 8

            SendPane {
                id: sendPane
                Layout.fillWidth: true
                Layout.fillHeight: true
            }

            QuickSendGrid {
                id: quickSendGrid
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                visible: root.showQuickSend
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

    // ── Settings dialog ────────────────────────────────────────
    SettingsDialog {
        id: settingsDialog
        appWindow: root
        appSettings: appSettings

        onAboutToShow: {
            settingsDialog.loadSettings()

            var btnPos = settingsButton.mapToItem(parent, 0, 0)
            var desiredX = btnPos.x + settingsButton.width - width
            x = Math.max(12, Math.min(desiredX, root.width - width - 12))

            var belowY = btnPos.y + settingsButton.height
            var availableBelow = root.height - belowY - 12
            var availableAbove = btnPos.y - 12
            var preferredHeight = 420

            if (availableBelow >= preferredHeight) {
                y = belowY
                height = preferredHeight
            } else if (availableAbove >= preferredHeight) {
                height = preferredHeight
                y = btnPos.y - height
            } else {
                height = Math.max(240, root.height - 24)
                y = 12 + (root.height - 24 - height) / 2
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
            var path = selectedFile.toString().replace(/^file:\/+/, "")
            SerialPort.startRecording(path)
        }
    }

    FileDialog {
        id: loadFileDialog
        title: qsTr("Load file to send")
        fileMode: FileDialog.OpenFile
        nameFilters: ["Text files (*.txt)", "Binary files (*.bin)", "All files (*)"]
        onAccepted: {
            var path = selectedFile.toString().replace(/^file:\/+/, "")
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
