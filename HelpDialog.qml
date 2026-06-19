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
    font.family: Theme.fontFamily
    width: 700
    height: 520

    parent: Overlay.overlay

    // ── Language resolution ──────────────────────────────────────
    property string langDir: AppSettings.language.startsWith("zh") ? "zh" : "en"

    // ── Tab definitions ──────────────────────────────────────────
    readonly property var pages: [
        { title: qsTr("Quick Send"), page: "quick_send", icon: "⚡" },
        { title: qsTr("Auto Log"),   page: "auto_log",   icon: "📋" },
        { title: qsTr("Shortcuts"),  page: "shortcuts",  icon: "⌨" },
        { title: qsTr("About"),      page: "about",      icon: "ℹ" }
    ]

    // ── Content cache ────────────────────────────────────────────
    // revision increments on cache invalidation — delegates bind to it
    // so their text bindings re-evaluate after preloadAll() repopulates the cache.
    property var contentCache: ({})
    property int _rev: 0

    function loadContent(page) {
        if (contentCache[page])
            return contentCache[page]

        var path = SerialPort.applicationDirPath() + "/help/" + langDir + "/" + page + ".html"
        var raw = SerialPort.readFile(path)

        if (raw.length === 0)
            raw = "<p style='color:" + Theme.error + "'>" + qsTr("Help file not found") + "</p><p><code>" + path + "</code></p>"

        // Wrap in styled HTML — Theme colors baked in as CSS
        var fg     = Theme.text.toString()
        var bg     = Theme.inputBg.toString()
        var link   = Theme.accent.toString()
        var codeFg = Theme.darkTheme ? "#D4D4D4" : "#333333"
        var codeBg = Theme.darkTheme ? "#2D2D2D" : "#F0F0F0"
        var hr     = Theme.border.toString()
        var hBg    = Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.04).toString()
        var mono   = Theme.monoFontFamily

        var accentBg = Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.08).toString()
        var accentBd = Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.25).toString()
        var tipBg    = Theme.darkTheme ? Qt.rgba(0.38, 0.72, 0.28, 0.10).toString()
                     : Qt.rgba(0.18, 0.63, 0.26, 0.08).toString()
        var tipBd    = Theme.darkTheme ? Qt.rgba(0.38, 0.72, 0.28, 0.35).toString()
                     : Qt.rgba(0.18, 0.63, 0.26, 0.25).toString()
        var warnBg   = Theme.darkTheme ? Qt.rgba(0.82, 0.60, 0.13, 0.10).toString()
                     : Qt.rgba(0.82, 0.60, 0.13, 0.08).toString()
        var warnBd   = Theme.darkTheme ? Qt.rgba(0.82, 0.60, 0.13, 0.35).toString()
                     : Qt.rgba(0.82, 0.60, 0.13, 0.25).toString()

        var html = "<html><head><style>"
                 // ── Base ─────────────────────────────────────
                 + "body { color:" + fg + "; font-size:" + Theme.fontSize + "px; line-height:1.6; margin:0; }"
                 + "a { color:" + link + "; text-decoration:none; }"
                 + "strong { font-weight:600; }"
                 // ── Headings ─────────────────────────────────
                 + "h1 { font-size:" + (Theme.fontSizeLarge + 2) + "px; font-weight:700; margin:0 0 12px 0; padding-bottom:8px; border-bottom:2px solid " + Theme.accent + "; }"
                 + "h2 { font-size:" + Theme.fontSizeMedium + "px; font-weight:600; margin:20px 0 8px 0; padding-left:10px; border-left:3px solid " + Theme.accent + "; }"
                 + "h3 { font-size:" + Theme.fontSize + "px; font-weight:600; margin:12px 0 4px 0; color:" + fg + "; }"
                 // ── Paragraphs & spacing ─────────────────────
                 + "p { margin:4px 0 8px 0; }"
                 // ── Code ─────────────────────────────────────
                 + "code { font-family:'" + mono + "'; font-size:" + (Theme.fontSize - 1) + "px; color:" + codeFg + "; background:" + codeBg + "; padding:1px 5px; border-radius:3px; }"
                 + "pre { font-family:'" + mono + "'; font-size:" + (Theme.fontSize - 1) + "px; color:" + codeFg + "; background:" + codeBg + "; padding:12px 14px; border-radius:6px; margin:8px 0 12px 0; white-space:pre-wrap; border-left:3px solid " + Theme.accent + "; }"
                 + "pre code { background:transparent; padding:0; }"
                 // ── Horizontal rule ──────────────────────────
                 + "hr { border:none; border-top:1px solid " + hr + "; margin:16px 0; }"
                 // ── Lists ────────────────────────────────────
                 + "ul, ol { margin:4px 0 10px 0; padding-left:22px; }"
                 + "li { margin:3px 0; }"
                 // ── Tables ───────────────────────────────────
                 + "table { border-collapse:collapse; width:100%; margin:8px 0 12px 0; }"
                 + "td { padding:7px 12px; border:1px solid " + hr + "; }"
                 + "th { padding:7px 12px; border:1px solid " + hr + "; background:" + hBg + "; font-weight:600; text-align:left; }"
                 // ── Callout boxes ────────────────────────────
                 + ".tip { background:" + tipBg + "; border:1px solid " + tipBd + "; border-radius:6px; padding:10px 14px; margin:10px 0; }"
                 + ".warn { background:" + warnBg + "; border:1px solid " + warnBd + "; border-radius:6px; padding:10px 14px; margin:10px 0; }"
                 + ".info { background:" + accentBg + "; border:1px solid " + accentBd + "; border-radius:6px; padding:10px 14px; margin:10px 0; }"
                 // ── Key-value grid (used for shortcuts) ──────
                 + ".kv { margin:6px 0; }"
                 + ".kv td { padding:8px 14px; border-bottom:1px solid " + hr + "; }"
                 + ".kv td:first-child { font-family:'" + mono + "'; font-size:" + (Theme.fontSize - 1) + "px; color:" + Theme.accent + "; white-space:nowrap; width:1%; }"
                 + "</style></head><body>" + raw + "</body></html>"

        contentCache[page] = html
        return html
    }

    // Preload all pages on dialog open
    function preloadAll() {
        langDir = AppSettings.language.startsWith("zh") ? "zh" : "en"
        for (var i = 0; i < pages.length; i++)
            loadContent(pages[i].page)
    }

    onAboutToShow: {
        preloadAll()
        _rev++
    }

    // ── Layout ───────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // ── Sidebar ──────────────────────────────────────────────
        Rectangle {
            Layout.preferredWidth: 140
            Layout.fillHeight: true
            color: Theme.darkTheme ? Qt.darker(Theme.panelBg, 1.15) : Qt.lighter(Theme.panelBg, 1.03)

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Sidebar header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    color: Theme.darkTheme ? Qt.darker(Theme.panelBg, 1.25) : Qt.lighter(Theme.panelBg, 1.06)
                    border.color: Theme.border
                    border.width: 1

                    Label {
                        anchors.centerIn: parent
                        text: "📖  " + qsTr("Topics")
                        color: Theme.text
                        font.family: Theme.fontFamily
                        font.pixelSize: Theme.fontSize
                        font.bold: true
                    }
                }

                // Tab list
                ListView {
                    id: tabList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 2
                    currentIndex: 0
                    model: root.pages
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: ItemDelegate {
                        id: tabDelegate
                        width: tabList.width
                        height: 36
                        highlighted: ListView.isCurrentItem

                        background: Rectangle {
                            color: {
                                if (tabDelegate.highlighted)
                                    return Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.12)
                                if (tabDelegate.hovered)
                                    return Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.06)
                                return "transparent"
                            }

                            // Active indicator bar
                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 3
                                height: tabDelegate.highlighted ? parent.height * 0.6 : 0
                                radius: 1.5
                                color: Theme.accent
                                Behavior on height { NumberAnimation { duration: 150 } }
                            }
                        }

                        contentItem: RowLayout {
                            spacing: 8
                            anchors.left: parent.left
                            anchors.leftMargin: 14

                            Label {
                                text: modelData.icon
                                font.pixelSize: 14
                            }
                            Label {
                                text: modelData.title
                                color: tabDelegate.highlighted ? Theme.accent : Theme.text
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.fontSize
                                font.weight: tabDelegate.highlighted ? Font.DemiBold : Font.Normal
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 100 } }
                            }
                        }

                        onClicked: tabList.currentIndex = index
                    }
                }

                // Sidebar footer
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Theme.border
                }
            }
        }

        // ── Content area ─────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Theme.inputBg

            StackLayout {
                id: contentStack
                anchors.fill: parent
                anchors.margins: 2
                currentIndex: tabList.currentIndex

                Repeater {
                    model: root.pages

                    Flickable {
                        id: flick
                        clip: true
                        contentHeight: helpArea.implicitHeight + 20
                        boundsBehavior: Flickable.StopAtBounds

                        ScrollBar.vertical: CustomScrollBar { policy: ScrollBar.AsNeeded }

                        TextEdit {
                            id: helpArea
                            width: flick.width - 20
                            x: 10
                            y: 10
                            readOnly: true
                            textFormat: Text.RichText
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            color: Theme.text
                            font.family: Theme.fontFamily
                            font.pixelSize: Theme.fontSize
                            // _rev forces re-evaluation after cache invalidation
                            text: { var _ = root._rev; return root.contentCache[modelData.page] || "" }
                            selectByMouse: false
                        }
                    }
                }
            }
        }
    }

    // ── Invalidate cache on theme / language change ──────────────
    function refreshContent() {
        contentCache = ({})
        _rev++
        preloadAll()
    }

    Connections {
        target: AppSettings
        function onLanguageChanged() { root.refreshContent() }
    }

    Connections {
        target: Theme
        function onDarkThemeChanged() { root.refreshContent() }
    }
}
