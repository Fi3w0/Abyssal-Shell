import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property int revision: 0
    property string output: "*"
    property int panelIndex: 0
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
    SettingGroup {
        title: "Position & shape"
        visible: root.panels.length > 0
        enabled: root.supported
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 128
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width, 500); height: 110
                radius: 8; color: Theme.deep; border.color: Theme.edge
                Rectangle {
                    readonly property bool vertical: root.panel.edge === "left" || root.panel.edge === "right"
                    x: root.panel.edge === "right" ? parent.width - width - 8 : vertical ? 8 : (parent.width - width)/2
                    y: root.panel.edge === "bottom" ? parent.height - height - 8 : 8
                    width: vertical ? 16 : parent.width * (root.panel.width === "custom" ? (root.panel.length || 100)/100 : root.panel.width === "fit" ? .5 : .94)
                    height: vertical ? parent.height - 16 : 16
                    radius: root.panel.floating ? 5 : 2; color: Theme.glowSoft; border.color: Theme.glowEdge
                    Row {
                        anchors.centerIn: parent
                        visible: !parent.vertical
                        spacing: 5
                        Repeater { model: Math.min((root.panel.items || []).length, 8); Rectangle { width: 5; height: 5; radius: 1; color: Theme.glow } }
                    }
                }
            }
        }
        Field { title: "Screen edge"; kind: "choice"; value: root.panel.edge || "top"; choices: ["top", "bottom", "left", "right"].map(v => ({value: v, label: v[0].toUpperCase()+v.slice(1)})); onEdited: next => root.change("edge", next) }
        Field { title: "Panel shape"; kind: "choice"; value: root.panel.width || "fill"; choices: [{value: "fill", label: "Full-width strip"}, {value: "fit", label: "Pill around widgets"}, {value: "islands", label: "Separate islands"}, {value: "custom", label: "Custom length"}]; onEdited: next => root.change("width", next) }
        Field { title: "Length"; visible: root.panel.width === "custom"; kind: "slider"; minimum: 10; maximum: 100; unit: "%"; value: root.panel.length || 100; onEdited: next => root.change("length", next) }
        Field { objectName: "panelThickness"; title: "Thickness"; kind: "slider"; minimum: 24; maximum: 96; unit: " px"; value: root.panel.size || 36; onEdited: next => root.change("size", next) }
        Field { title: "Float away from the screen edge"; kind: "bool"; value: root.panel.floating === true; onEdited: next => root.change("floating", next) }
        Field { title: "Surface"; kind: "choice"; value: root.panel.look || "glass"; choices: [{value: "glass", label: "Glass"}, {value: "solid", label: "Solid"}]; onEdited: next => root.change("look", next) }
        Field { title: "Visibility"; kind: "choice"; value: root.panel.visibility || "always"; choices: [{value: "always", label: "Always visible"}, {value: "autohide", label: "Hide automatically"}, {value: "below", label: "Let windows cover it"}]; onEdited: next => root.change("visibility", next) }
    }
}
