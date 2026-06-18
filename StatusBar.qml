import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import CWY.Serial

Rectangle {
    id: root
    height: 28
    color: _panelBg
    border.color: _border

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
        ColorAnimation { target: rxTxLabel; property: "color"; to: _accent; duration: 100 }
        ColorAnimation { target: rxTxLabel; property: "color"; to: _text; duration: 400 }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        spacing: 12

        Rectangle {
            width: 8
            height: 8
            radius: 4
            color: SerialPort.isOpen ? _success : _error
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

        Label {
            text: SerialPort.isOpen
                  ? qsTr("Connected")
                  : qsTr("Disconnected")
            color: _text
            font.pixelSize: 12
        }

        Label {
            text: "|"
            color: _text
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
            color: _text
            font.pixelSize: 12
        }

        Item { Layout.fillWidth: true }

        Label {
            id: rxTxLabel
            text: qsTr("RX: %1 | TX: %2").arg(root.rxCount).arg(root.txCount)
            color: _text
            font.pixelSize: 12
            font.family: "Consolas"
        }
    }
}
