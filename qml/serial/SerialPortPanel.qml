import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Ripple.Serial
import Ripple.Theme
import Ripple.NotificationManager

MainPanel {
    id: root

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.spacingPanel
        spacing: Theme.spacingSection

        Label {
            text: qsTr("Serial Port")
            font.bold: true
            color: Theme.text
        }

        // Port selection — click to refresh
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: portCombo.implicitHeight

            FluentComboBox {
                id: portCombo
                anchors.fill: parent
                textRole: "display"
                valueRole: "name"
                enabled: !SerialPort.isOpen
                model: ListModel { id: portModel }
                popup.y: portCombo.height + 4
                onActivated: SerialPort.portName = currentValue

                TextMetrics {
                    id: textMetrics
                    font: portCombo.font
                }
            }

            // Intercept mouse press on the combo to refresh ports before popup opens
            MouseArea {
                anchors.fill: parent
                propagateComposedEvents: true
                enabled: !SerialPort.isOpen
                onPressed: function(mouse) {
                    if (!portCombo.popup.opened) {
                        refreshPorts()
                    }
                    // Don't open popup if there are no ports
                    mouse.accepted = portModel.count === 0
                }
            }
        }

        // Baud rate — editable combo: pick from list or type any value
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4
            Label {
                text: qsTr("Baud Rate")
                color: Theme.text
                font.pixelSize: Theme.fontSize
            }
            FluentComboBox {
                id: baudCombo
                Layout.fillWidth: true
                enabled: !SerialPort.isOpen
                editable: true
                model: ["1200","2400","4800","9600","19200","38400",
                        "57600","115200","230400","460800","921600"]
                editText: String(SerialPort.baudRate)
                validator: IntValidator { bottom: 1; top: 4000000 }
                popup.y: baudCombo.height + 4

                onActivated: (index) => SerialPort.baudRate = parseInt(currentValue)
                onAccepted: {
                    var rate = parseInt(editText)
                    if (!isNaN(rate) && rate > 0)
                        SerialPort.baudRate = rate
                }
            }
        }

        // Data bits
        ParamCombo {
            label: qsTr("Data Bits")
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
                color: SerialPort.isOpen ? Theme.error : Theme.success
                radius: Theme.radiusInput
                opacity: connectButton.down || !connectButton.enabled ? 0.7 : 1.0
            }
        }

        Item { Layout.fillHeight: true }
    }

    Component.onCompleted: {
        refreshPorts()
        // Sync port selection when refreshed
        SerialPort.portNameChanged.connect(function() {
            portCombo.currentIndex = portCombo.indexOfValue(SerialPort.portName)
        })
        // Sync baud rate combo selection
        baudCombo.currentIndex = baudCombo.model.indexOf(String(SerialPort.baudRate))
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
        updatePopupWidth()
        NotificationManager.info(qsTr("串口列表已刷新"))
    }

    function updatePopupWidth() {
        var maxW = portCombo.width
        for (var i = 0; i < portModel.count; ++i) {
            var item = portModel.get(i)
            textMetrics.text = item ? item.display : ""
            maxW = Math.max(maxW, textMetrics.advanceWidth + 32)
        }
        portCombo.popup.width = maxW
    }
}
