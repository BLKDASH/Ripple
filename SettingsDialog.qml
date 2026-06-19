import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import CWY.AppSettings
import CWY.Serial
import CWY.I18n
import CWY.Receive
import CWY.Theme
import CWY.NotificationManager

Dialog {
    id: root
    title: qsTr("Settings")
    font.family: Theme.fontFamily
    modal: true

    // Anchor to the overlay so manual geometry in onAboutToShow wins over
    // the default centre placement.
    parent: Overlay.overlay

    property var appWindow
    property string selectedLanguage: "en"

    function loadSettings() {
        selectedLanguage = AppSettings.language
        themeCombo.currentIndex = Theme.darkTheme ? 0 : 1
        showQuickSendCheck.checked = appWindow ? appWindow.showQuickSend : false
        autoLogCheck.checked = AppSettings.autoLogEnabled
        logPathField.text = AppSettings.autoLogFolder
    }

    function applySettings() {
        // Auto-log conflict check
        if (autoLogCheck.checked && SerialPort.wouldAutoLogConflict(autoLogCheck.checked, logPathField.text)) {
            NotificationManager.error(qsTr("Auto-log file conflicts with the current recording file"))
            return false
        }

        Theme.darkTheme = (themeCombo.currentIndex === 0)
        if (appWindow)
            appWindow.showQuickSend = showQuickSendCheck.checked

        var lang = languageCombo.currentValue
        if (lang !== AppSettings.language) {
            AppSettings.language = lang
            Translator.setCurrentLanguage(lang)
        }

        SerialPort.autoLogEnabled = autoLogCheck.checked
        SerialPort.autoLogFolder = logPathField.text
        return true
    }

    width: 420
    height: 420

    footer: RowLayout {
        spacing: 8
        Item { Layout.fillWidth: true }
        Button {
            text: qsTr("Cancel")
            onClicked: root.reject()
        }
        Button {
            text: qsTr("OK")
            highlighted: true
            onClicked: {
                if (root.applySettings())
                    root.accept()
            }
        }
    }

    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.margins: 12
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
                label: Label {
                    text: parent.title
                    color: Theme.text
                    font.bold: true
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 8
                    Label {
                        text: qsTr("Theme")
                        color: Theme.text
                    }
                    FluentComboBox {
                        id: themeCombo
                        Layout.fillWidth: true
                        model: [qsTr("Dark"), qsTr("Light")]
                        popup.y: themeCombo.height + 4
                        currentIndex: Theme.darkTheme ? 0 : 1
                    }

                    Label {
                        text: qsTr("Language")
                        color: Theme.text
                    }
                    FluentComboBox {
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
                label: Label {
                    text: parent.title
                    color: Theme.text
                    font.bold: true
                }

                ColumnLayout {
                    width: parent.width
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
                label: Label {
                    text: parent.title
                    color: Theme.text
                    font.bold: true
                }

                ColumnLayout {
                    width: parent.width
                    spacing: 8
                    CheckBox {
                        id: autoLogCheck
                        text: qsTr("Enable auto log")
                        checked: AppSettings.autoLogEnabled
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        TextField {
                            id: logPathField
                            Layout.fillWidth: true
                            text: AppSettings.autoLogFolder
                            placeholderText: qsTr("Select log folder...")
                            color: Theme.text
                        }
                        Button {
                            text: qsTr("Browse")
                            onClicked: logFolderDialog.open()
                        }
                    }
                }
            }
        }
    }

    FolderDialog {
        id: logFolderDialog
        title: qsTr("Select auto log folder")
        onAccepted: logPathField.text = selectedFolder.toString().replace(/^file:\/\/+/, "")
    }
}
