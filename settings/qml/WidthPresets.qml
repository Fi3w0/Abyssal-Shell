import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property var value: []
    signal edited(var next)
    spacing: 8
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: root.value
            ArchiveButton {
                required property var modelData
                text: Math.round(modelData * 100) + "%  ×"
                Accessible.name: "Remove " + Math.round(modelData * 100) + " percent width"
                enabled: root.value.length > 1
                onClicked: root.edited(root.value.filter(v => Math.abs(v-modelData) > .001))
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        ArchiveSpinBox { id: newWidth; from: 10; to: 100; value: 50; editable: true; Accessible.name: "New preset width in percent"; Layout.fillWidth: true }
        ArchiveButton {
            text: "Add width"
            enabled: root.value.length < 16 && !root.value.some(v => Math.abs(v-newWidth.value/100) < .001)
            onClicked: root.edited(root.value.concat([newWidth.value/100]).sort((a,b) => a-b))
        }
    }
}
