import QtQuick
import QtQuick.Controls as C

C.TextField {
    id: control
    implicitHeight: Math.max(30, contentHeight + 12 * Theme.density)
    padding: 8 * Theme.density
    color: Theme.text
    placeholderTextColor: Theme.subtext
    selectionColor: Theme.glowSoft
    selectedTextColor: Theme.text
    font.family: Theme.fontFamily
    font.pixelSize: 12
    selectByMouse: true
    opacity: enabled ? 1 : 0.5
    background: Rectangle {
        color: Theme.deep
        radius: Theme.radius
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? Theme.glow : Theme.edge
    }
}
