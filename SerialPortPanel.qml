import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.Serial

Rectangle {
    id: root
    color: themePalette.panel
    border.color: themePalette.border
    radius: 4

    property var themePalette

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Label {
            text: qsTr("Serial Port")
            font.bold: true
            color: themePalette.text
        }

        // Port selection
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            ComboBox {
                id: portCombo
                Layout.fillWidth: true
                textRole: "display"
                valueRole: "name"
                enabled: !SerialPort.isOpen
                model: ListModel { id: portModel }
                popup.y: portCombo.height + 4
                popup.width: {
                    var maxW = portCombo.width
                    for (var i = 0; i < portModel.count; ++i) {
                        var item = portModel.get(i)
                        textMetrics.text = item ? item.display : ""
                        maxW = Math.max(maxW, textMetrics.advanceWidth + 32)
                    }
                    return maxW
                }
                onActivated: SerialPort.portName = currentValue

                TextMetrics {
                    id: textMetrics
                    font: portCombo.font
                }
            }
            Label {
                id: refreshIcon
                text: "🔃"
                font.pixelSize: 18
                color: SerialPort.isOpen ? themePalette.border : themePalette.text
                enabled: !SerialPort.isOpen
                opacity: enabled ? 1.0 : 0.4

                ToolTip.visible: refreshMouseArea.containsMouse
                ToolTip.text: qsTr("Refresh ports")

                MouseArea {
                    id: refreshMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        refreshPorts()
                        refreshAnim.start()
                    }
                    cursorShape: Qt.PointingHandCursor
                }

                RotationAnimator on rotation {
                    id: refreshAnim
                    from: 0
                    to: 360
                    duration: 400
                    running: false
                }
            }
        }

        // Baud rate
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Label {
                text: qsTr("Baud Rate")
                color: themePalette.text
                font.pixelSize: 12
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                ComboBox {
                    id: baudCombo
                    Layout.fillWidth: true
                    enabled: !SerialPort.isOpen
                    model: [1200, 2400, 4800, 9600, 19200, 38400, 57600, 115200, 230400, 460800, 921600, qsTr("Custom")]
                    popup.y: baudCombo.height + 4
                    Component.onCompleted: syncBaud()

                    onActivated: {
                        if (currentIndex === count - 1) {
                            customBaudField.text = SerialPort.baudRate
                            customBaudField.forceActiveFocus()
                            customBaudField.selectAll()
                        } else {
                            SerialPort.baudRate = currentValue
                        }
                    }

                    function syncBaud() {
                        var idx = indexOfValue(SerialPort.baudRate)
                        if (idx !== -1) {
                            currentIndex = idx
                        } else {
                            currentIndex = count - 1
                        }
                    }
                }

                TextField {
                    id: customBaudField
                    Layout.preferredWidth: 90
                    visible: baudCombo.currentIndex === baudCombo.count - 1
                    enabled: !SerialPort.isOpen
                    text: SerialPort.baudRate
                    color: themePalette.text
                    font.family: "Consolas"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    validator: IntValidator { bottom: 1; top: 99999999 }
                    background: Rectangle {
                        color: themePalette.background
                        border.color: themePalette.border
                        radius: 4
                    }
                    onEditingFinished: {
                        var rate = parseInt(text)
                        if (!isNaN(rate) && rate > 0) {
                            SerialPort.baudRate = rate
                        }
                    }
                }
            }
        }

        // Data bits
        ParamCombo {
            label: qsTr("Data Bits")
            themePalette: root.themePalette
            model: [
                { value: 5, text: "5" },
                { value: 6, text: "6" },
                { value: 7, text: "7" },
                { value: 8, text: "8" }
            ]
            currentValue: SerialPort.dataBits
            onValueChanged: (value) => SerialPort.dataBits = value
        }

        // Stop bits
        ParamCombo {
            label: qsTr("Stop Bits")
            themePalette: root.themePalette
            model: [
                { value: 1, text: "1" },
                { value: 3, text: "1.5" },
                { value: 2, text: "2" }
            ]
            currentValue: SerialPort.stopBits
            onValueChanged: (value) => SerialPort.stopBits = value
        }

        // Parity
        ParamCombo {
            label: qsTr("Parity")
            themePalette: root.themePalette
            model: [
                { value: 0, text: qsTr("None") },
                { value: 2, text: qsTr("Even") },
                { value: 3, text: qsTr("Odd") },
                { value: 4, text: qsTr("Space") },
                { value: 5, text: qsTr("Mark") }
            ]
            currentValue: SerialPort.parity
            onValueChanged: (value) => SerialPort.parity = value
        }

        // Flow control
        ParamCombo {
            label: qsTr("Flow Control")
            themePalette: root.themePalette
            model: [
                { value: 0, text: qsTr("None") },
                { value: 1, text: qsTr("Hardware") },
                { value: 2, text: qsTr("Software") }
            ]
            currentValue: SerialPort.flowControl
            onValueChanged: (value) => SerialPort.flowControl = value
        }

        // Connect / Disconnect button
        Button {
            id: connectButton
            Layout.fillWidth: true
            text: SerialPort.isOpen ? qsTr("Disconnect") : qsTr("Connect")
            onClicked: SerialPort.isOpen ? SerialPort.closePort() : SerialPort.openPort()

            contentItem: Label {
                text: connectButton.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                font.bold: true
            }

            background: Rectangle {
                implicitHeight: 32
                color: SerialPort.isOpen ? "#E57373" : "#81C784"
                radius: 4
                opacity: connectButton.down ? 0.8 : 1.0
            }
        }

        Item { Layout.fillHeight: true }
    }

    Component.onCompleted: {
        refreshPorts()
        // Keep baud combo in sync with C++ property
        SerialPort.baudRateChanged.connect(function() {
            baudCombo.syncBaud()
        })
        // Sync port selection when refreshed
        SerialPort.portNameChanged.connect(function() {
            portCombo.currentIndex = portCombo.indexOfValue(SerialPort.portName)
        })
    }

    function refreshPorts() {
        portModel.clear()
        var ports = SerialPort.availablePorts()
        var selectedIndex = -1
        for (var i = 0; i < ports.length; ++i) {
            var p = ports[i]
            portModel.append({
                name: p.name,
                display: p.name + (p.description ? " (" + p.description + ")" : "")
            })
            if (p.name === SerialPort.portName) selectedIndex = i
        }
        if (ports.length > 0 && SerialPort.portName === "") {
            SerialPort.portName = ports[0].name
        }
        portCombo.currentIndex = selectedIndex >= 0 ? selectedIndex : 0
    }
}
