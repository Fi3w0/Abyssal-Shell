import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ColumnLayout {
    id: root
    property string kind: "theme"
    property string status: ""
    signal imported(string presetId)
    spacing: 8
    function save() {
        const id = kind === "theme" ? Store.saveTheme(presetName.text) : Store.savePanelPreset(presetName.text);
        status = Store.message;
        if (id) { nameRow.visible = false; presetName.clear(); imported(id); }
    }
    RowLayout {
        Layout.fillWidth: true
        ArchiveButton { objectName: root.kind + "SaveAs"; text: "Save as…"; onClicked: { nameRow.visible = !nameRow.visible; if (nameRow.visible) presetName.forceActiveFocus(); } }
        ArchiveButton { objectName: root.kind + "Import"; text: "Import…"; onClicked: loadFile.open() }
        ArchiveButton { objectName: root.kind + "Export"; text: "Export…"; onClicked: saveFile.open() }
        Item { Layout.fillWidth: true }
    }
    RowLayout {
        id: nameRow
        visible: false
        Layout.fillWidth: true
        ArchiveTextField { id: presetName; objectName: root.kind + "PresetName"; Layout.fillWidth: true; placeholderText: "Preset name"; Accessible.name: root.kind + " preset name"; maximumLength: 80; onAccepted: root.save() }
        ArchiveButton { objectName: root.kind + "SavePreset"; text: "Save preset"; enabled: presetName.text.trim().length > 0; highlighted: true; onClicked: root.save() }
        ArchiveButton { text: "Cancel"; onClicked: nameRow.visible = false }
    }
    Label { visible: root.status !== ""; Layout.fillWidth: true; text: root.status; color: Theme.subtext; font.pixelSize: 10; wrapMode: Text.WordWrap }
    FileDialog {
        id: loadFile
        title: root.kind === "theme" ? "Import theme" : "Import panel preset"
        nameFilters: ["JSON presets (*.json)"]
        onAccepted: {
            const id = Store.importPreset(root.kind, selectedFile);
            root.status = Store.message;
            if (id) root.imported(id);
        }
    }
    FileDialog {
        id: saveFile
        title: root.kind === "theme" ? "Export current theme" : "Export current panel layout"
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: ["JSON presets (*.json)"]
        onAccepted: { Store.exportPreset(root.kind, "", selectedFile); root.status = Store.message; }
    }
}
