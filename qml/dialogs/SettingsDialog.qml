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

Item {
    id: root
    anchors.fill: parent
    z: 100
    visible: opacity > 0
    opacity: opened ? 1.0 : 0.0
    enabled: opened

    Behavior on opacity { NumberAnimation { duration: 200 } }

    property bool opened: false
    property var appWindow
    property string selectedLanguage: "en"

    function open()  { opened = true }
    function close() { opened = false }
    function toggle() { opened = !opened }

    function loadSettings() {
        selectedLanguage = AppSettings.language
        themeCombo.currentIndex = Theme.darkTheme ? 0 : 1
        autoLogCheck.checked = AppSettings.autoLogEnabled
        logPathField.text = AppSettings.autoLogFolder
    }

    function applySettings() {
        if (autoLogCheck.checked && SerialPort.wouldAutoLogConflict(autoLogCheck.checked, logPathField.text)) {
            NotificationManager.error(qsTr("Auto-log file conflicts with the current recording file"))
            return false
        }
        Theme.darkTheme = (themeCombo.currentIndex === 0)
        var lang = languageCombo.currentValue
        if (lang !== AppSettings.language) {
            AppSettings.language = lang
            Translator.setCurrentLanguage(lang)
        }
        SerialPort.autoLogEnabled = autoLogCheck.checked
        SerialPort.autoLogFolder = logPathField.text
        return true
    }

    // ── Semi-transparent backdrop ────────────────────────────
    Rectangle {
        id: backdrop
        anchors.fill: parent
        color: "black"
        opacity: 0.3

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    // ── Slide-in panel ───────────────────────────────────────
    Rectangle {
        id: panel
        x: root.opened ? 0 : -width
        width: 360
        height: parent.height
        color: Theme.panelBg

        Behavior on x {
            NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
        }

        // Right edge shadow
        Rectangle {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            width: 1
            color: Theme.darkTheme ? "#333" : "#ccc"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // ── Title bar ─────────────────────────────────────
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                color: Theme.panelBg

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 8

                    Label {
                        text: qsTr("Settings")
                        font.pixelSize: 16
                        font.bold: true
                        font.family: Theme.fontFamily
                        color: Theme.text
                        Layout.fillWidth: true
                    }

                    Button {
                        id: closeBtn
                        flat: true
                        text: "✕"
                        font.pixelSize: 16
                        onClicked: root.close()
                        background: Rectangle {
                            radius: 4
                            color: closeBtn.hovered ? (Theme.darkTheme ? "#333" : "#e0e0e0") : "transparent"
                        }
                        contentItem: Text {
                            text: closeBtn.text
                            font: closeBtn.font
                            color: Theme.text
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.darkTheme ? "#333" : "#ddd" }

            // ── Scrollable content ────────────────────────────
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: column.implicitHeight + 24
                flickableDirection: Flickable.VerticalFlick
                clip: true

                ColumnLayout {
                    id: column
                    width: parent.width - 24
                    x: 16
                    spacing: 16

                    Item { Layout.preferredHeight: 8 }

                    GroupBox {
                        Layout.fillWidth: true
                        title: qsTr("Appearance")
                        label: Label {
                            text: parent.title
                            color: Theme.text
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                        ColumnLayout {
                            width: parent.width
                            spacing: 8
                            Label { text: qsTr("Theme"); color: Theme.text; font.family: Theme.fontFamily }
                            FluentComboBox {
                                id: themeCombo
                                Layout.fillWidth: true
                                model: [qsTr("Dark"), qsTr("Light")]
                                popup.y: themeCombo.height + 4
                                currentIndex: Theme.darkTheme ? 0 : 1
                            }
                            Label { text: qsTr("Language"); color: Theme.text; font.family: Theme.fontFamily }
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
                        title: qsTr("Auto Log")
                        label: Label {
                            text: parent.title
                            color: Theme.text
                            font.bold: true
                            font.family: Theme.fontFamily
                        }
                        ColumnLayout {
                            width: parent.width
                            spacing: 8
                            CheckBox {
                                id: autoLogCheck
                                text: qsTr("Enable auto log")
                                checked: AppSettings.autoLogEnabled
                                indicator.width: 16; indicator.height: 16
                                font.family: Theme.fontFamily
                            }
                            RowLayout {
                                Layout.fillWidth: true
                                TextField {
                                    id: logPathField
                                    Layout.fillWidth: true
                                    text: AppSettings.autoLogFolder
                                    placeholderText: qsTr("Select log folder...")
                                    color: Theme.text
                                    font.family: Theme.fontFamily
                                }
                                Button {
                                    text: qsTr("Browse")
                                    font.family: Theme.fontFamily
                                    onClicked: logFolderDialog.open()
                                }
                            }
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.darkTheme ? "#333" : "#ddd" }

            // ── Footer buttons ────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: 8

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    font.family: Theme.fontFamily
                    onClicked: root.close()
                }
                Button {
                    text: qsTr("OK")
                    highlighted: true
                    font.family: Theme.fontFamily
                    onClicked: {
                        if (root.applySettings())
                            root.close()
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
