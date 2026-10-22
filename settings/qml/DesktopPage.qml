import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property string pageId: "windows"
    property string query: ""
    property int revision: 0
    readonly property var definition: Store.desktopPages.find(v => v.id === pageId) || {groups: []}
    readonly property string engine: { revision; return Store.desktopValue("engine", "classic"); }
    Connections { target: Store; function onChanged() { root.revision++; } }
    spacing: 16 * Theme.density
    Label {
        visible: !Store.desktopEditable
        text: "Desktop controls need TideWM’s wavefmt validator. Install it with TideWM to enable saving."
        wrapMode: Text.WordWrap
        color: Theme.warn
        Layout.fillWidth: true
    }
    Repeater {
        model: root.definition.groups
        SettingGroup {
            required property var modelData
            title: modelData.title
            visible: (!modelData.engine || modelData.engine === root.engine) && (!root.query || modelData.rows.some(r => (r.title + " " + (r.hint || "") + " " + r.key).toLowerCase().includes(root.query)))
            Layout.fillWidth: true
            enabled: Store.desktopEditable
            Label { visible: !!modelData.hint; text: modelData.hint || ""; color: Theme.subtext; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            ArchiveButton {
                visible: root.pageId === "input" && modelData.rows.some(r => r.deviceDefault)
                text: "Restore existing device settings"
                onClicked: { for (const row of modelData.rows) if (row.deviceDefault) Store.setDesktopValue(row.key, "device-default"); }
            }
            Repeater {
                model: modelData.rows
                Field {
                    required property var modelData
                    objectName: modelData.key
                    visible: (!modelData.engine || modelData.engine === root.engine) && (!root.query || (modelData.title + " " + (modelData.hint || "") + " " + modelData.key).toLowerCase().includes(root.query))
                    title: modelData.title
                    hint: modelData.hint || (modelData.deviceDefault && modelData.kind === "slider" ? "Moving this slider overrides the device’s existing speed." : "")
                    kind: modelData.deviceDefault && modelData.kind === "bool" ? "choice" : modelData.kind
                    choices: modelData.deviceDefault && modelData.kind !== "slider" ? [{value: "device-default", label: "Keep existing device setting"}].concat(modelData.kind === "bool" ? [{value: true, label: "On"}, {value: false, label: "Off"}] : modelData.choices || []) : modelData.choices || []
                    minimum: modelData.min === undefined ? 0 : modelData.min
                    maximum: modelData.max === undefined ? 100 : modelData.max
                    unit: modelData.unit || ""
                    value: {
                        root.revision;
                        const v = Store.desktopValue(modelData.key, modelData.default);
                        if (modelData.deviceDefault && (v === null || v === undefined)) return modelData.kind === "slider" ? 0 : "device-default";
                        return modelData.scale ? v * modelData.scale : v;
                    }
                    onEdited: next => Store.setDesktopValue(modelData.key, modelData.scale ? next/modelData.scale : next)
                }
            }
        }
    }
    SettingGroup {
        visible: root.pageId === "input"
        title: "Try your keyboard"
        ArchiveTextField { Layout.fillWidth: true; placeholderText: "Type here to test layouts and repeat speed…"; Accessible.name: "Keyboard test" }
    }
    Item { Layout.preferredHeight: 12 }
}
