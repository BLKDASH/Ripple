import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import CWY.Serial
import CWY.I18n
import CWY.Receive

Dialog {
    id: root
    title: qsTr("Settings")
    standardButtons: Dialog.Ok | Dialog.Cancel
    modal: true

    property var appWindow
    property var appSettings

    property string selectedLanguage: "en"

    function loadSettings() {
        selectedLanguage = appSettings ? appSettings.language : "en"
        themeCombo.currentIndex = appWindow && appWindow.darkTheme ? 0 : 1
        showQuickSendCheck.checked = appWindow ? appWindow.showQuickSend : false
        autoLogCheck.checked = appSettings ? appSettings.autoLogEnabled : false
        logPathField.text = appSettings ? appSettings.autoLogPath : ""
    }

    width: 420
    height: 420

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: width
        contentHeight: column.implicitHeight
        flickableDirection: Flickable.VerticalFlick
        clip: true

        ColumnLayout {
            id: column
            width: flickable.width
            spacing: 16

            GroupBox {
                Layout.fillWidth: true
                title: qsTr("Appearance")
            background: Rectangle {
                color: _inputBg
                border.color: _border
                radius: 4
            }
            label: Label {
                text: parent.title
                color: _text
                font.bold: true
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                Label {
                    text: qsTr("Theme")
                    color: _text
                }
                ComboBox {
                    id: themeCombo
                    Layout.fillWidth: true
                    model: [qsTr("Dark"), qsTr("Light")]
                    popup.y: themeCombo.height + 4
                    currentIndex: appWindow && appWindow.darkTheme ? 0 : 1
                }

                Label {
                    text: qsTr("Language")
                    color: _text
                }
                ComboBox {
                    id: languageCombo
                    Layout.fillWidth: true
                    textRole: "text"
                    valueRole: "code"
                    popup.y: languageCombo.height + 4
                    model: [
                        { text: "English", code: "en" },
                        { text: "简体中文", code: "zh_CN" }
                    ]
                    currentIndex: indexOfValue(root.selectedLanguage)
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Receive")
            background: Rectangle {
                color: _inputBg
                border.color: _border
                radius: 4
            }
            label: Label {
                text: parent.title
                color: _text
                font.bold: true
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                CheckBox {
                    id: showQuickSendCheck
                    text: qsTr("Show quick send panel")
                    checked: appWindow ? appWindow.showQuickSend : false
                }
            }
        }

        GroupBox {
            Layout.fillWidth: true
            title: qsTr("Auto Log")
            background: Rectangle {
                color: _inputBg
                border.color: _border
                radius: 4
            }
            label: Label {
                text: parent.title
                color: _text
                font.bold: true
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 8
                CheckBox {
                    id: autoLogCheck
                    text: qsTr("Enable auto log")
                    checked: appSettings ? appSettings.autoLogEnabled : false
                }
                RowLayout {
                    Layout.fillWidth: true
                    TextField {
                        id: logPathField
                        Layout.fillWidth: true
                        text: appSettings ? appSettings.autoLogPath : ""
                        placeholderText: qsTr("Select log file path...")
                        color: _text
                        background: Rectangle {
                            color: _inputBg
                            border.color: _border
                            radius: 4
                        }
                    }
                    Button {
                        text: qsTr("Browse")
                        onClicked: logFileDialog.open()
                    }
                }
            }
        }
        }
    }

    FileDialog {
        id: logFileDialog
        title: qsTr("Select auto log file")
        fileMode: FileDialog.SaveFile
        nameFilters: ["Log files (*.log)", "Text files (*.txt)", "All files (*)"]
        onAccepted: logPathField.text = selectedFile.toString().replace(/^file:\/+/, "")
    }

    onAccepted: {
        if (appWindow) {
            appWindow.darkTheme = (themeCombo.currentIndex === 0)
            appWindow.showQuickSend = showQuickSendCheck.checked
        }

        SerialPort.autoLogEnabled = autoLogCheck.checked
        SerialPort.autoLogPath = logPathField.text

        if (appSettings) {
            var lang = languageCombo.currentValue
            if (lang !== appSettings.language) {
                appSettings.language = lang
                Translator.setCurrentLanguage(lang)
            }
            appSettings.autoLogEnabled = SerialPort.autoLogEnabled
            appSettings.autoLogPath = SerialPort.autoLogPath
        }
    }
}
