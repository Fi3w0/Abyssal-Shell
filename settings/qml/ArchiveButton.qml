import QtQuick
import QtQuick.Controls as C

C.Button {
    id: control
    implicitHeight: Math.max(28, contentItem.implicitHeight + 12 * Theme.density)
    implicitWidth: contentItem.implicitWidth + 22 * Theme.density
    padding: 8 * Theme.density
    hoverEnabled: true
    font.family: Theme.fontFamily
    font.pixelSize: 11
    opacity: enabled ? 1 : 0.5
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.highlighted || control.checked ? Theme.glow : Theme.text
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: Theme.radius
        color: control.down ? Theme.glowSoft : control.hovered ? Theme.glass : Theme.deep
        border.color: control.visualFocus ? Theme.glow : control.highlighted || control.checked ? Theme.glowEdge : Theme.edge
        border.width: control.visualFocus ? 2 : 1
        Behavior on color { ColorAnimation { duration: 120 } }
    }
}
