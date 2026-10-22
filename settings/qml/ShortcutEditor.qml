import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

GridLayout {
    id: root
    property string chord: ""
    property string action: ""
    property string actionLabel: "Custom action (keep existing)"
    property var actions: []
    property bool recording: false
    property string buttonText: "Update"
    signal saved(string chord, string action)
    columns: width < 650 ? 1 : 3
    columnSpacing: 12
    rowSpacing: 8
    Layout.fillWidth: true
    ShortcutRecorder { Layout.preferredWidth: 220; Layout.fillWidth: root.columns === 1; chord: root.chord; onRecorded: next => root.chord = next; onRecordingChanged: root.recording = recording }
    ArchiveComboBox {
        id: selector
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        model: root.actions.some(v => v.value === root.action) || !root.action ? root.actions : [{value: root.action, label: root.actionLabel}].concat(root.actions)
        textRole: "label"
        valueRole: "value"
        currentIndex: root.action ? model.findIndex(v => v.value === root.action) : 0
        Accessible.name: "Shortcut action"
        onActivated: root.action = currentValue
    }
    ArchiveButton { objectName: "shortcutSubmit"; text: root.buttonText; enabled: !!root.chord && !!selector.currentValue; onClicked: root.saved(root.chord, selector.currentValue) }
}
