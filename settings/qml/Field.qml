import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    implicitWidth: 380
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
    spacing: 16 * Theme.density
    Layout.topMargin: 8 * Theme.density
    Layout.bottomMargin: 8 * Theme.density
    Layout.fillWidth: true
    ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 100
        spacing: 4
        Label {
            text: root.title
            color: Theme.text
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
        Label {
            visible: root.hint !== ""
            text: root.hint
            color: Theme.subtext
            font.pixelSize: 10
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
    Loader {
        Layout.preferredWidth: root.kind === "bool" ? 46 : root.kind === "number" ? 120 : 220
        sourceComponent: root.kind === "bool" ? toggle : root.kind === "number" ? number : root.kind === "choice" ? choice : root.kind === "real" ? realNumber : root.kind === "slider" ? slider : input
    }
    Component {
        id: toggle
        ArchiveSwitch {
            objectName: "switch"
            Accessible.name: root.title
            Accessible.description: root.hint
            checked: !!root.value
            onToggled: root.edited(checked)
        }
    }
    Component {
        id: number
        ArchiveSpinBox {
            objectName: "stepper"
            from: root.minimum
            to: root.maximum
            value: Number(root.value) || 0
            editable: true
            Accessible.name: root.title
            Accessible.description: root.hint
            onValueModified: root.edited(value)
        }
    }
    Component {
        id: choice
        ArchiveComboBox {
            objectName: "choice"
            model: root.choices
            textRole: "label"
            valueRole: "value"
            currentIndex: root.choices.findIndex(v => v.value === root.value)
            Accessible.name: root.title
            Accessible.description: root.hint
            onActivated: root.edited(currentValue)
        }
    }
    Component {
        id: input
        ArchiveTextField {
            text: String(root.value === undefined ? "" : root.value)
            Accessible.name: root.title
            Accessible.description: root.hint
            selectByMouse: true
            onEditingFinished: if (text !== String(root.value))
                root.edited(text)
        }
    }
    Component {
        id: realNumber
        ArchiveTextField {
            text: String(root.value)
            Accessible.name: root.title
            Accessible.description: root.hint
            selectByMouse: true
            validator: DoubleValidator {
                bottom: root.minimum
                top: root.maximum
                notation: DoubleValidator.StandardNotation
                locale: "C"
            }
            onEditingFinished: if (acceptableInput)
                root.edited(Number(text))
        }
    }
    Component {
        id: slider
        RowLayout {
            ArchiveSlider {
                id: range
                objectName: "slider"
                Layout.fillWidth: true
                from: root.minimum
                to: root.maximum
                stepSize: root.step
                value: Number(root.value) || 0
                Accessible.name: root.title
                Accessible.description: root.hint
                onMoved: root.edited(value)
            }
            Label { text: Math.round(range.value) + root.unit; color: Theme.glow; font.pixelSize: 12; font.bold: true; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight }
        }
    }
}
