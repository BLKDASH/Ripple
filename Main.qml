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

    // Theme colors
    property bool darkTheme: false
    readonly property color bgColor: darkTheme ? "#E51E1E1E" : "#E5F0F0F0"
    readonly property color panelColor: darkTheme ? "#E8252526" : "#EAF3F3F3"
    readonly property color backgroundColor: darkTheme ? "#E51E1E1E" : "#E5FFFFFF"
    readonly property color borderColor: darkTheme ? "#303C3C3C" : "#30E5E5E5"
    readonly property color textColor: darkTheme ? "#E8E8E8" : "#151515"
    readonly property color accentColor: darkTheme ? "#4CA6FF" : "#0067C0"
    readonly property color successColor: "#2EA043"
    readonly property color errorColor: "#F85149"
    readonly property color warningColor: "#D29922"

    // Persistent settings
    Settings {
        id: appSettings
        property alias darkTheme: root.darkTheme
        property alias showQuickSend: root.showQuickSend
        property string language: "zh_CN"
        property bool autoLogEnabled: false
        property string autoLogPath: ""
    }

    property bool showQuickSend: false

    color: bgColor

    palette {
        window: panelColor
        windowText: textColor
        base: backgroundColor
        alternateBase: panelColor
        text: textColor
        button: panelColor
        buttonText: textColor
        highlight: accentColor
        highlightedText: "white"
        toolTipBase: panelColor
        toolTipText: textColor
    }

    // Background gradient simulating a desktop wallpaper for glass effect
    Rectangle {
        anchors.fill: parent
        z: -1
        gradient: Gradient {
            GradientStop { position: 0.0; color: darkTheme ? "#1A2A3A" : "#C8E0F5" }
            GradientStop { position: 0.5; color: darkTheme ? "#2A1A3A" : "#E0D0F0" }
            GradientStop { position: 1.0; color: darkTheme ? "#0A1A2A" : "#F0E0D0" }
        }
    }

    Component.onCompleted: {
        SerialPort.errorOccurred.connect(function(msg) {
            errorPopup.text = msg
            errorPopup.open()
        })

        Translator.setCurrentLanguage(appSettings.language)
        SerialPort.autoLogEnabled = appSettings.autoLogEnabled
        SerialPort.autoLogPath = appSettings.autoLogPath
    }

    // Top toolbar placeholder
    header: ToolBar {
        height: 44
        background: Rectangle { color: panelColor }
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
                text: root.darkTheme ? "☀" : "🌙"
                onClicked: root.darkTheme = !root.darkTheme
            }
        }
    }

    // Main content area
    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        // Left: serial port config panel
        SerialPortPanel {
            Layout.preferredWidth: 200
            Layout.fillHeight: true
            themePalette: {
                "panel": panelColor,
                "background": backgroundColor,
                "border": borderColor,
                "text": textColor,
                "success": successColor,
                "error": errorColor
            }
        }

        // Center: receive area
        ReceivePane {
            id: receivePane
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.minimumWidth: 200
            themePalette: {
                "panel": panelColor,
                "background": backgroundColor,
                "border": borderColor,
                "text": textColor,
                "accent": accentColor
            }
            onClearRequested: {
                rxCount = 0
            }
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
                themePalette: {
                    "panel": panelColor,
                    "border": borderColor,
                    "background": backgroundColor,
                    "text": textColor,
                    "error": errorColor
                }
            }

            QuickSendGrid {
                id: quickSendGrid
                Layout.fillWidth: true
                Layout.preferredHeight: 220
                visible: root.showQuickSend
                themePalette: {
                    "panel": panelColor,
                    "border": borderColor,
                    "background": backgroundColor,
                    "text": textColor
                }
            }
        }
    }

    // Bottom status bar
    footer: StatusBar {
        themePalette: {
            "panel": panelColor,
            "border": borderColor,
            "text": textColor,
            "accent": accentColor,
            "success": successColor,
            "error": errorColor
        }
        rxCount: root.rxCount
        txCount: root.txCount
    }

    Connections {
        target: SerialPort
        function onBytesReceived(count) { rxCount += count }
        function onBytesSent(count) { txCount += count }
    }

    // Data model removed; ReceivePane maintains its own model.
    property int rxCount: 0
    property int txCount: 0

    SettingsDialog {
        id: settingsDialog
        themePalette: {
            "panel": panelColor,
            "border": borderColor,
            "background": backgroundColor,
            "text": textColor
        }
        appWindow: root
        appSettings: appSettings

        onAboutToShow: {
            settingsDialog.loadSettings()

            var btnPos = settingsButton.mapToItem(parent, 0, 0)
            // Right-align the dialog with the settings button and keep inside window
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
                // Window is too small: shrink dialog and center vertically
                height = Math.max(240, root.height - 24)
                y = 12 + (root.height - 24 - height) / 2
            }
        }
    }

    // Error popup
    Popup {
        id: errorPopup
        property alias text: errorLabel.text
        x: (parent.width - width) / 2
        y: 12
        width: 400
        height: 60
        modal: false
        focus: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        background: Rectangle {
            color: errorColor
            radius: 4
        }
        contentItem: Label {
            id: errorLabel
            color: "white"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            wrapMode: Text.Wrap
        }
    }

    // File dialogs
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
