import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Control {
    id: root
    property string title
    property string hint: ""
    property string kind: "text"
    property var value
    property var choices: []
    property real minimum: 0
    property real maximum: 100
    property real step: 1
    property string unit: ""
    signal edited(var next)
    implicitWidth: 380
    implicitHeight: contentItem.implicitHeight + topPadding + bottomPadding
    padding: 0
    topPadding: 12 * Theme.density
    bottomPadding: 12 * Theme.density
    Layout.fillWidth: true
    contentItem: GridLayout {
        columns: ["engine", "layouts", "presets"].includes(root.kind) || (root.width < 480 && ["choice", "text"].includes(root.kind)) ? 1 : 2
        columnSpacing: 20 * Theme.density
        rowSpacing: 8 * Theme.density
        ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            Layout.preferredWidth: root.width * 0.45
            spacing: 4
            Label { text: root.title; color: Theme.text; font.pixelSize: 12; font.weight: Font.Medium; wrapMode: Text.WordWrap; Layout.fillWidth: true }
            Label { visible: root.hint !== ""; text: root.hint; color: Theme.subtext; font.pixelSize: 10; wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
        Loader {
            Layout.fillWidth: parent.columns === 1
            Layout.preferredWidth: root.kind === "bool" ? 44 : root.kind === "number" ? 158 : ["engine", "layouts", "presets"].includes(root.kind) ? root.width : 220
            Layout.maximumWidth: root.availableWidth
            Layout.alignment: Qt.AlignRight
            sourceComponent: ({bool: toggle, number: number, choice: choice, real: realNumber, slider: slider, engine: enginePicker, presets: presets, layouts: layouts})[root.kind] || input
        }
    }
    background: Rectangle { color: "transparent"; Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.edge } }
    Component { id: toggle; ArchiveSwitch { objectName: "switch"; Accessible.name: root.title; Accessible.description: root.hint; checked: !!root.value; onToggled: root.edited(checked) } }
    Component { id: number; ArchiveSpinBox { objectName: "stepper"; from: root.minimum; to: root.maximum; value: Number(root.value) || 0; editable: true; Accessible.name: root.title; Accessible.description: root.hint; onValueModified: root.edited(value) } }
    Component {
        id: choice
        ArchiveComboBox {
            objectName: "choice"
            model: root.choices; textRole: "label"; valueRole: "value"
            currentIndex: root.choices.findIndex(v => v.value === root.value)
            Accessible.name: root.title; Accessible.description: root.hint
            onActivated: root.edited(currentValue)
        }
    }
    Component { id: input; ArchiveTextField { text: String(root.value === undefined ? "" : root.value); Accessible.name: root.title; Accessible.description: root.hint; onEditingFinished: if (text !== String(root.value)) root.edited(text) } }
    Component {
        id: realNumber
        ArchiveTextField {
            text: String(root.value); Accessible.name: root.title; Accessible.description: root.hint
            validator: DoubleValidator { bottom: root.minimum; top: root.maximum; notation: DoubleValidator.StandardNotation; locale: "C" }
            onEditingFinished: if (acceptableInput) root.edited(Number(text))
        }
    }
    Component {
        id: slider
        RowLayout {
            spacing: 10
            ArchiveSlider { id: range; objectName: "slider"; Layout.fillWidth: true; from: root.minimum; to: root.maximum; stepSize: root.step; value: Number(root.value) || 0; Accessible.name: root.title; Accessible.description: root.hint; onMoved: root.edited(value) }
            Label { text: Number(range.value.toFixed(root.step < 1 ? 1 : 0)) + root.unit; color: Theme.glow; font.pixelSize: 11; font.bold: true; Layout.preferredWidth: Math.max(46, implicitWidth); horizontalAlignment: Text.AlignRight }
        }
    }
    Component { id: enginePicker; EnginePicker { value: root.value; onSelected: next => root.edited(next) } }
    Component { id: presets; WidthPresets { value: root.value; onEdited: next => root.edited(next) } }
    Component { id: layouts; KeyboardLayouts { value: root.value; onEdited: next => root.edited(next) } }
}
