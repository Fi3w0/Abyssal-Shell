import QtQuick
import QtQuick.Controls

AbstractButton {
    id: control
    property string symbol
    property bool destructive: false
    implicitWidth: 34
    implicitHeight: 30
    hoverEnabled: true
    Accessible.name: text
    ToolTip.visible: hovered
    ToolTip.text: text
    contentItem: Item { ArchiveIcon { anchors.centerIn: parent; width: 14; height: 14; symbol: control.symbol; tint: control.destructive && control.hovered ? Theme.danger : control.hovered ? Theme.text : Theme.subtext } }
    background: Rectangle { radius: 7; color: control.down ? Theme.glowSoft : control.destructive && control.hovered ? Theme.alpha(Theme.danger, 0.12) : control.hovered ? Theme.glass : "transparent"; border.width: control.visualFocus ? 2 : 0; border.color: Theme.glow; Behavior on color { ColorAnimation { duration: 120 } } }
}
