import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property int revision: 0
    property string output: "*"
    property int panelIndex: 0
    property string selectedPreset: Store.panelPresets.length ? Store.panelPresets[0].id : ""
    readonly property var preset: Store.panelPresets.find(p => p.id === selectedPreset) || null
    readonly property var monitors: { revision; return Store.value("layout", "monitors", {}); }
    readonly property var panels: ((monitors[output] || monitors["*"] || {}).panels || [])
    readonly property var panel: panels[panelIndex] || {}
    readonly property var outputs: [{value: "*", label: "Shared defaults for all displays"}].concat(Array.from(new Set(Store.outputs().concat(Object.keys(monitors)))).filter(v => v !== "*").map(v => ({value: v, label: v})))
    readonly property bool supported: { revision; return Store.value("layout", "version", 2) === 2; }
    Connections { target: Store; function onChanged() { root.revision++; } }
    function change(key, value) {
        const all = JSON.parse(JSON.stringify(monitors));
        const entry = JSON.parse(JSON.stringify(monitors[output] || monitors["*"] || {panels: []}));
        entry.panels[panelIndex][key] = value;
        all[output] = entry;
        Store.setValue("layout", "monitors", all);
        Store.setValue("layout", "version", 2);
    }
    function add() {
        const all = JSON.parse(JSON.stringify(monitors));
        const entry = JSON.parse(JSON.stringify(monitors[output] || monitors["*"] || {panels: []}));
        entry.panels.push({edge: "top", width: "fill", align: "center", length: 100, look: "glass", floating: true, size: 36, visibility: "always", items: ["workspaces", "spacer", "clock", "tray"]});
        all[output] = entry;
        panelIndex = entry.panels.length - 1;
        Store.setValue("layout", "monitors", all);
        Store.setValue("layout", "version", 2);
    }
    spacing: 16
    SettingGroup {
        title: "Panel presets"
        PresetActions { kind: "panels"; Layout.fillWidth: true; onImported: presetId => root.selectedPreset = presetId }
        Label { text: "Save all displays, panels and widget options together. Loading replaces the current layout draft; Save changes applies it."; color: Theme.subtext; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true; Layout.topMargin: 8 }
        RowLayout {
            visible: Store.panelPresets.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 10
            ArchiveComboBox {
                objectName: "panelPresetChoice"
                Layout.fillWidth: true
                model: Store.panelPresets
                textRole: "name"; valueRole: "id"
                currentIndex: model.findIndex(p => p.id === root.selectedPreset)
                Accessible.name: "Saved panel preset"
                onActivated: root.selectedPreset = currentValue
            }
            ArchiveButton { objectName: "loadPanelPreset"; text: "Load preset"; enabled: !!root.preset; onClicked: { if (Store.loadPanelPreset(root.selectedPreset)) root.panelIndex = 0; } }
        }

    }
    SettingGroup {
        title: "Your panels"
        RowLayout {
            Layout.fillWidth: true
            ArchiveComboBox { Layout.fillWidth: true; model: root.outputs; textRole: "label"; valueRole: "value"; currentIndex: model.findIndex(v => v.value === root.output); Accessible.name: "Display for panel settings"; onActivated: { root.output = currentValue; root.panelIndex = 0; } }
            ArchiveButton { objectName: "addPanel"; text: "Add panel"; enabled: root.supported; onClicked: root.add() }
            ArchiveButton { text: "Arrange widgets"; onClicked: Store.launch("panels") }
        }
        ArchiveComboBox {
            Layout.fillWidth: true
            Layout.topMargin: 10
            visible: root.panels.length > 0
            model: root.panels.map((p, i) => ({value: i, label: "Panel " + (i+1) + " · " + p.edge + " · " + (p.items || []).length + " widgets"}))
            textRole: "label"; valueRole: "value"; currentIndex: root.panelIndex
            Accessible.name: "Panel to edit"
            onActivated: root.panelIndex = currentValue
        }
        Label { visible: !root.supported; text: "Open Arrange widgets once to upgrade this older panel layout."; color: Theme.warn; font.pixelSize: 11; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        Label { visible: root.panels.length === 0; text: "No panels on this display yet. Add one above."; color: Theme.subtext; font.pixelSize: 11; Layout.fillWidth: true }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: root.width >= 760 ? 2 : 1
        columnSpacing: 14; rowSpacing: 14
    SettingGroup {
        title: "Position & shape"
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        visible: root.panels.length > 0
        enabled: root.supported
        Field { title: "Screen edge"; kind: "choice"; value: root.panel.edge || "top"; choices: ["top", "bottom", "left", "right"].map(v => ({value: v, label: v[0].toUpperCase()+v.slice(1)})); onEdited: next => root.change("edge", next) }
        Field { title: "Panel shape"; kind: "choice"; value: root.panel.width || "fill"; choices: [{value: "fill", label: "Full-width strip"}, {value: "fit", label: "Pill around widgets"}, {value: "islands", label: "Separate islands"}, {value: "custom", label: "Custom length"}]; onEdited: next => root.change("width", next) }
        Field { title: "Alignment"; kind: "choice"; value: root.panel.align || "center"; choices: [{value:"start",label:"Start"},{value:"center",label:"Centre"},{value:"end",label:"End"}]; onEdited: next => root.change("align", next) }
        Field { title: "Length"; visible: root.panel.width === "custom"; kind: "slider"; minimum: 10; maximum: 100; unit: "%"; value: root.panel.length || 100; onEdited: next => root.change("length", next) }
        Field { objectName: "panelThickness"; title: "Thickness"; kind: "slider"; minimum: 24; maximum: 96; unit: " px"; value: root.panel.size || 36; onEdited: next => root.change("size", next) }
        Field { title: "Float away from the screen edge"; kind: "bool"; value: root.panel.floating === true; onEdited: next => root.change("floating", next) }
        Field { title: "Surface"; kind: "choice"; value: root.panel.look || "glass"; choices: [{value: "glass", label: "Glass"}, {value: "solid", label: "Solid"}]; onEdited: next => root.change("look", next) }
        Field { title: "Visibility"; kind: "choice"; value: root.panel.visibility || "always"; choices: [{value: "always", label: "Always visible"}, {value: "autohide", label: "Hide automatically"}, {value: "below", label: "Let windows cover it"}]; onEdited: next => root.change("visibility", next) }
    }
    ColumnLayout {
        Layout.fillWidth: true
        Layout.preferredWidth: 1
        Layout.alignment: Qt.AlignTop
        spacing: 14
        PanelPreview { Layout.fillWidth: true; panels: root.panels; selectedIndex: root.panelIndex; displayName: root.output === "*" ? "Shared defaults · current draft" : root.output + " · current draft" }
        Label { text: "Current draft · " + root.panels.length + " panels · " + (root.panel.items || []).length + " widgets in the selected panel"; color: Theme.subtext; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        SettingGroup {
            visible: !!root.preset
            title: "Saved preset preview"
        PanelPreview {
            visible: !!root.preset
            Layout.fillWidth: true
            Layout.topMargin: 10
            displayName: root.preset ? root.preset.name + " · saved layout" : ""
            panels: root.preset ? ((root.preset.layout.monitors[root.output] || root.preset.layout.monitors["*"] || Object.values(root.preset.layout.monitors)[0] || {}).panels || []) : []
        }
        }
    }
    }

}
