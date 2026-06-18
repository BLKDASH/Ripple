import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.AppSettings
import CWY.Serial
import CWY.Theme

Dialog {
    id: root
    title: qsTr("Help")
    standardButtons: Dialog.Ok
    modal: true
    width: 700
    height: 520

    parent: Overlay.overlay

    // ── Resolve language subdirectory ────────────────────────────
    readonly property string langDir: AppSettings.language.startsWith("zh") ? "zh" : "en"

    function helpPath(page) {
        return SerialPort.applicationDirPath() + "/help/" + langDir + "/" + page + ".html"
    }

    function loadHelp(page) {
        var path = helpPath(page)
        var content = SerialPort.readFile(path)
        if (content.length === 0)
            content = "## " + qsTr("Help file not found") + "\n\n" + path
        return content
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Left tab bar ──────────────────────────────────────────
        TabBar {
            id: tabBar
            Layout.preferredWidth: 120
            Layout.fillHeight: true

            contentItem: ListView {
                model: tabBar.contentModel
                currentIndex: tabBar.currentIndex
                spacing: 2
                interactive: false
                boundsBehavior: Flickable.StopAtBounds
            }

            background: Rectangle {
                color: Theme.panelBg
                border.color: Theme.border
            }

            TabButton { text: qsTr("Quick Send"); width: 120 }
            TabButton { text: qsTr("Auto Log");  width: 120 }
            TabButton { text: qsTr("Shortcuts"); width: 120 }
            TabButton { text: qsTr("About");     width: 120 }
        }

        // ── Right content area ────────────────────────────────────
        StackLayout {
            id: stack
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: tabBar.currentIndex

            // Quick Send ─────────────────────────────────────────────
            Flickable {
                id: flickQS
                clip: true
                contentHeight: qsArea.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                TextArea {
                    id: qsArea
                    width: parent.width - 16
                    height: implicitHeight
                    readOnly: true
                    textFormat: Text.RichText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    leftPadding: 8
                    rightPadding: 8
                    color: Theme.text
                    font.pixelSize: Theme.fontSize
                    text: loadHelp("quick_send")
                    background: Rectangle { color: Theme.inputBg; radius: 4 }
                }
            }

            // Auto Log ───────────────────────────────────────────────
            Flickable {
                id: flickAL
                clip: true
                contentHeight: alArea.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                TextArea {
                    id: alArea
                    width: parent.width - 16
                    height: implicitHeight
                    readOnly: true
                    textFormat: Text.RichText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    leftPadding: 8
                    rightPadding: 8
                    color: Theme.text
                    font.pixelSize: Theme.fontSize
                    text: loadHelp("auto_log")
                    background: Rectangle { color: Theme.inputBg; radius: 4 }
                }
            }

            // Shortcuts ──────────────────────────────────────────────
            Flickable {
                id: flickSC
                clip: true
                contentHeight: scArea.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                TextArea {
                    id: scArea
                    width: parent.width - 16
                    height: implicitHeight
                    readOnly: true
                    textFormat: Text.RichText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    leftPadding: 8
                    rightPadding: 8
                    color: Theme.text
                    font.pixelSize: Theme.fontSize
                    text: loadHelp("shortcuts")
                    background: Rectangle { color: Theme.inputBg; radius: 4 }
                }
            }

            // About ──────────────────────────────────────────────────
            Flickable {
                id: flickAB
                clip: true
                contentHeight: abArea.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                TextArea {
                    id: abArea
                    width: parent.width - 16
                    height: implicitHeight
                    readOnly: true
                    textFormat: Text.RichText
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    leftPadding: 8
                    rightPadding: 8
                    color: Theme.text
                    font.pixelSize: Theme.fontSize
                    text: loadHelp("about")
                    background: Rectangle { color: Theme.inputBg; radius: 4 }
                }
            }
        }
    }

    // Reload content when language changes (settings dialog may change it)
    Connections {
        target: AppSettings
        function onLanguageChanged() {
            // Force re-evaluation of bound text properties by
            // re-assigning after a short delay to let the .qm reload.
            reloadTimer.start()
        }
    }

    Timer {
        id: reloadTimer
        interval: 100
        repeat: false
        onTriggered: {
            langDir = AppSettings.language.startsWith("zh") ? "zh" : "en"
            qsArea.text = loadHelp("quick_send")
            alArea.text = loadHelp("auto_log")
            scArea.text = loadHelp("shortcuts")
            abArea.text = loadHelp("about")
        }
    }
}
