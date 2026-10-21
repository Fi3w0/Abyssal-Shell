import QtQuick
import "../services"

Rectangle {
    id: root
    property string value: ""
    property string label: "Text"
    signal committed(string value)
    implicitWidth: 180
    implicitHeight: Theme.controlHeight
    radius: Theme.controlRadius
    color: Theme.chip
    border { width: 1; color: editor.activeFocus ? Theme.accent : Theme.hairline }
    function commit() { if (editor.text !== value) committed(editor.text) }
    Binding { target: editor; property: "text"; value: root.value; when: !editor.activeFocus; restoreMode: Binding.RestoreNone }
    TextInput {
        id: editor
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 10 }
        clip: true
        color: Theme.text
        font { family: Theme.font; pixelSize: Theme.controlFontSize }
        selectByMouse: true; activeFocusOnTab: true
        selectionColor: Theme.accent; selectedTextColor: Theme.crust
        Accessible.name: root.label
        onAccepted: root.commit()
        onActiveFocusChanged: if (!activeFocus) root.commit()
        Keys.onEscapePressed: { text = root.value; focus = false }
    }
}
