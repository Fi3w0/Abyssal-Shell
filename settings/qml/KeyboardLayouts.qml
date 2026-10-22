import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string value: "us"
    readonly property var installed: Store.keyboardLayouts()
    signal edited(string next)
    spacing: 8
    Flow {
        Layout.fillWidth: true
        spacing: 6
        Repeater {
            model: root.value.split(",").filter(v => v)
            ArchiveButton {
                required property string modelData
                text: (root.installed.find(v => v.value === modelData) || {label: modelData}).label + "  ×"
                enabled: root.value.split(",").length > 1
                Accessible.name: "Remove " + text
                onClicked: root.edited(root.value.split(",").filter(v => v !== modelData).join(","))
            }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        ArchiveComboBox { id: layout; Layout.fillWidth: true; model: root.installed; textRole: "label"; valueRole: "value"; Accessible.name: "Keyboard layout to add" }
        ArchiveButton { text: "Add"; enabled: !!layout.currentValue && !root.value.split(",").includes(layout.currentValue); onClicked: root.edited(root.value ? root.value + "," + layout.currentValue : layout.currentValue) }
    }
}
