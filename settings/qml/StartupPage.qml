import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property int revision: 0
    readonly property var installed: Store.applications()
    readonly property var entries: { revision; return Store.value("autostart", "apps", []); }
    Connections { target: Store; function onChanged() { root.revision++; } }
    spacing: 16
    SettingGroup {
        title: "Start when you sign in"
        Label { text: "Choose installed apps. They will start the next time you sign in."; color: Theme.subtext; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
            ArchiveComboBox { id: app; Layout.fillWidth: true; Layout.minimumWidth: 0; model: root.installed; textRole: "label"; valueRole: "value"; Accessible.name: "App to start at login" }
            ArchiveButton {
                text: "Add app"
                enabled: !!app.currentValue && !root.entries.some(v => v.command === app.currentValue.slice(6))
                onClicked: { const next = root.entries.slice(); next.push({name: app.currentText, command: app.currentValue.slice(6), enabled: true}); Store.setAutostart(next); }
            }
        }
    }
    SettingGroup {
        title: "Your startup apps"
        Repeater {
            model: root.entries
            RowLayout {
                required property var modelData
                required property int index
                Layout.fillWidth: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                ArchiveSwitch { checked: modelData.enabled !== false; Accessible.name: "Enable " + (modelData.name || "startup app"); onToggled: { const next = root.entries.slice(); next[index] = Object.assign({}, next[index], {enabled: checked}); Store.setAutostart(next); } }
                Label { text: modelData.name || "Custom startup app"; color: Theme.text; Layout.fillWidth: true; elide: Text.ElideRight }
                ArchiveButton { text: "Remove"; onClicked: { const next = root.entries.slice(); next.splice(index, 1); Store.setAutostart(next); } }
            }
        }
        Label { visible: root.entries.length === 0; text: "No additional apps selected."; color: Theme.subtext; font.pixelSize: 11 }
    }
}
