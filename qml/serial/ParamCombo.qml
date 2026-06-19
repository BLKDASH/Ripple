import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Ripple.Serial
import Ripple.Theme

ColumnLayout {
    id: root
    Layout.fillWidth: true
    spacing: 4

    property string label
    property var model
    property int currentValue
    signal valueChanged(int value)

    Label {
        text: root.label
        color: Theme.text
        font.pixelSize: Theme.fontSize
    }

    FluentComboBox {
        id: combo
        Layout.fillWidth: true
        enabled: !SerialPort.isOpen
        model: root.model
        textRole: "text"
        valueRole: "value"
        popup.y: combo.height + 4

        Component.onCompleted: syncIndex()
        onModelChanged: syncIndex()

        onActivated: {
            if (root.currentValue !== currentValue)
                root.valueChanged(currentValue)
        }
    }

    onCurrentValueChanged: syncIndex()

    function syncIndex() {
        var idx = combo.indexOfValue(root.currentValue)
        if (idx !== -1 && combo.currentIndex !== idx)
            combo.currentIndex = idx
    }
}
