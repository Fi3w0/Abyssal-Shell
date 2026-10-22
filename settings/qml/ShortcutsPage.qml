import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property bool recording: false
    property string query: ""
    readonly property var installed: Store.applications()
    function describe(action) {
        const known = actions.find(a => a.value === action);
        if (known) return known.label;
        if (action.startsWith("spawn:")) {
            const command = action.slice(6).trim().split(/\s+/)[0].split("/").pop();
            const app = installed.find(a => (a.command || "").split(/\s+/)[0].split("/").pop() === command);
            if (app) return "Open " + app.label;
        }
        return "Custom action (keep existing)";
    }
    readonly property var actions: [
        {value: "close-window", label: "Close window"}, {value: "toggle-floating", label: "Toggle floating window"},
        {value: "toggle-fullscreen", label: "Toggle fullscreen"}, {value: "toggle-overview", label: "Show overview"},
        {value: "focus-left", label: "Focus left"}, {value: "focus-right", label: "Focus right"},
        {value: "focus-up", label: "Focus above"}, {value: "focus-down", label: "Focus below"},
        {value: "workspace:1", label: "Workspace 1"}, {value: "workspace:2", label: "Workspace 2"},
        {value: "workspace:3", label: "Workspace 3"}, {value: "workspace:4", label: "Workspace 4"},
        {value: "workspace:5", label: "Workspace 5"}, {value: "switch-preset-width", label: "Cycle column widths"},
        {value: "center-column", label: "Centre column"}, {value: "maximize-column", label: "Maximize column"}
    ].concat(installed.map(v => ({value: v.value, label: "Open " + v.label})))
    spacing: 16
    SettingGroup {
        title: "New shortcut"
        Label { text: "Record the keys, then choose a desktop action or an installed app."; color: Theme.subtext; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        ShortcutEditor {
            id: add
            Layout.topMargin: 12
            actions: root.actions
            buttonText: "Add shortcut"
            onRecordingChanged: root.recording = recording
            onSaved: (chord, action) => {
                if (Store.addShortcut(chord, action)) add.chord = "";
            }
        }
    }
    SettingGroup {
        title: "Your shortcuts"
        Repeater {
            model: Store.bindings
            ShortcutEditor {
                required property var modelData
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                visible: !root.query || (modelData.chord + " " + root.describe(modelData.action)).toLowerCase().includes(root.query)
                chord: modelData.chord
                action: modelData.action
                actionLabel: root.describe(modelData.action)
                actions: root.actions
                enabled: !modelData.readOnly
                onRecordingChanged: root.recording = recording
                onSaved: (chord, action) => Store.setBinding(modelData.id, modelData.line, chord, action)
            }
        }
        Label { visible: Store.bindings.length === 0; text: "No shortcuts yet. Add one above."; color: Theme.subtext; font.pixelSize: 11 }
    }
    Item { Layout.preferredHeight: 12 }
}
