import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property string title
    property string hint: ""
    property string kind: "text"
    property var value
    property var choices: []
    property int minimum: 0
    property int maximum: 100
    signal edited(var next)
    spacing: 22
    Layout.fillWidth: true
    ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 160
        spacing: 4
        Label {
            text: root.title
            color: "#ece5f4"
            font.pixelSize: 14
        }
        Label {
            visible: root.hint !== ""
            text: root.hint
            color: "#9d91ad"
            font.pixelSize: 11
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }
    }
    Loader {
        Layout.preferredWidth: root.kind === "bool" ? 46 : root.kind === "number" ? 120 : 260
        sourceComponent: root.kind === "bool" ? toggle : root.kind === "number" ? number : root.kind === "choice" ? choice : root.kind === "real" ? realNumber : input
    }
    Component {
        id: toggle
        Switch {
            checked: !!root.value
            onToggled: root.edited(checked)
        }
    }
    Component {
        id: number
        SpinBox {
            from: root.minimum
            to: root.maximum
            value: Number(root.value) || 0
            editable: true
            onValueModified: root.edited(value)
        }
    }
    Component {
        id: choice
        ComboBox {
            model: root.choices
            textRole: "label"
            valueRole: "value"
            currentIndex: root.choices.findIndex(v => v.value === root.value)
            onActivated: root.edited(currentValue)
        }
    }
    Component {
        id: input
        TextField {
            text: String(root.value === undefined ? "" : root.value)
            selectByMouse: true
            onEditingFinished: if (text !== String(root.value))
                root.edited(text)
        }
    }
    Component {
        id: realNumber
        TextField {
            text: String(root.value)
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
}
