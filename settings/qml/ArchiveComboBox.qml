import QtQuick
import QtQuick.Controls as C

C.ComboBox {
    id: control
    implicitHeight: Math.max(30, contentItem.implicitHeight + 12 * Theme.density)
    font.family: Theme.fontFamily
    font.pixelSize: 11
    leftPadding: 10
    rightPadding: 26
    opacity: enabled ? 1 : 0.5
    contentItem: Text {
        text: control.displayText
        font: control.font
        color: Theme.text
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Text {
        x: control.width - width - 10
        y: (control.height - height) / 2
        text: "⌄"
        color: Theme.subtext
        font.pixelSize: 13
        rotation: control.popup.visible ? 180 : 0
        Behavior on rotation { NumberAnimation { duration: Theme.duration } }
    }
    background: Rectangle {
        color: Theme.deep
        radius: Theme.radius
        border.color: control.visualFocus ? Theme.glow : control.hovered ? Theme.glowEdge : Theme.edge
        border.width: control.visualFocus ? 2 : 1
    }
}
