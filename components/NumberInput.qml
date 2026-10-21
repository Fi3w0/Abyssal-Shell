import QtQuick
import "../services"

Rectangle {
    id: root

    property int value: 0
    property int minimum: 0
    property int maximum: 100
    property string suffix: ""
    property string label: "Value"
    signal committed(int value)

    // An external control (such as the paired slider) also updates the
    // draft while this field still has keyboard focus.
    onValueChanged: if (editor.activeFocus) editor.text = String(value)

    implicitWidth: 128
    implicitHeight: Theme.controlHeight
    radius: Theme.controlRadius
    color: Theme.chip
    border.width: 1
    border.color: editor.activeFocus ? Theme.accent : Theme.hairline
    opacity: enabled ? 1 : 0.4

    function commit() {
        const draft = editor.text.trim()
        const number = Number(draft)
        const next = draft !== "" && Number.isFinite(number)
            ? Math.max(minimum, Math.min(maximum, Math.round(number))) : value
        editor.text = String(next)
        if (next !== value) committed(next)
    }

    Binding {
        target: editor
        property: "text"
        value: String(root.value)
        when: !editor.activeFocus
        restoreMode: Binding.RestoreNone
    }

    TextInput {
        id: editor
        anchors { left: parent.left; right: unit.left; verticalCenter: parent.verticalCenter; leftMargin: 12; rightMargin: 8 }
        color: Theme.text
        font { family: Theme.monoFont; pixelSize: Theme.controlFontSize }
        horizontalAlignment: TextInput.AlignRight
        selectByMouse: true
        activeFocusOnTab: true
        selectionColor: Theme.accent
        selectedTextColor: Theme.crust
        inputMethodHints: Qt.ImhDigitsOnly
        validator: IntValidator { bottom: 0; top: 9999 }
        Accessible.name: root.label
        onAccepted: root.commit()
        onActiveFocusChanged: {
            if (activeFocus) Qt.callLater(selectAll)
            else root.commit()
        }
        Keys.onEscapePressed: {
            text = String(root.value)
            focus = false
        }
    }

    Text {
        id: unit
        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
        text: root.suffix
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 12 }
    }
}
