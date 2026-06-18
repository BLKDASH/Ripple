import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.Serial
import CWY.Theme

Rectangle {
    id: root
    height: 28
    color: Theme.panelBg
    border.color: Theme.border
    radius: 4

    property int rxCount: 0
    property int txCount: 0

    onRxCountChanged: {
        if (root.rxCount > 0) flashColorAnim.start()
    }
    onTxCountChanged: {
        if (root.txCount > 0) flashColorAnim.start()
    }

    SequentialAnimation {
        id: flashColorAnim
        ColorAnimation { target: rxTxLabel; property: "color"; to: Theme.accent; duration: 100 }
        ColorAnimation { target: rxTxLabel; property: "color"; to: Theme.text; duration: 400 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        // Combined status indicator.
        // Inner dot  → connection status (green pulsing / red still).
        // Outer ring → auto-log active (visible only when auto-log is enabled).
        Item {
            width: 14
            height: 14

            // Outer ring — only visible when auto-log is enabled
            Rectangle {
                anchors.centerIn: parent
                width: 14
                height: 14
                radius: 7
                color: "transparent"
                border.color: SerialPort.isOpen ? Theme.success : Theme.error
                border.width: 1
                visible: SerialPort.autoLogEnabled
                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }

            // Inner dot — always visible, shows connection status
            Rectangle {
                anchors.centerIn: parent
                width: 8
                height: 8
                radius: 4
                color: SerialPort.isOpen ? Theme.success : Theme.error
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: SerialPort.isOpen
                    NumberAnimation { from: 1.0; to: 0.4; duration: 800 }
                    NumberAnimation { from: 0.4; to: 1.0; duration: 800 }
                }
            }
        }

        Label {
            text: SerialPort.isOpen
                  ? qsTr("Connected")
                  : qsTr("Disconnected")
            color: Theme.text
            font.pixelSize: 12
        }

        Label {
            text: "|"
            color: Theme.text
            font.pixelSize: 12
        }

        Label {
            text: SerialPort.isOpen
                  ? qsTr("%1 | %2 %3%4%5 %6")
                    .arg(SerialPort.portName)
                    .arg(SerialPort.baudRate)
                    .arg(SerialPort.dataBits)
                    .arg(["N", "?", "E", "O", "S", "M"][SerialPort.parity] || "N")
                    .arg(SerialPort.stopBits === 3 ? "1.5" : SerialPort.stopBits)
                    .arg(["None", "HW", "SW"][SerialPort.flowControl] || "None")
                  : qsTr("No port")
            color: Theme.text
            font.pixelSize: 12
        }

        Item { Layout.fillWidth: true }

        Label {
            id: rxTxLabel
            text: qsTr("RX: %1 | TX: %2").arg(root.rxCount).arg(root.txCount)
            color: Theme.text
            font.pixelSize: 12
            font.family: "Consolas"
        }
    }
}
