import QtQuick
import QtQuick.Controls as C

C.Switch {
    id: control
    padding: 4
    implicitWidth: 42
    implicitHeight: 28 * Theme.density
    hoverEnabled: true
    opacity: enabled ? 1 : 0.5
    indicator: Rectangle {
        x: (control.width - width) / 2
        y: (control.height - height) / 2
        width: 34
        height: 20
        radius: 10
        color: control.checked ? Theme.glowSoft : Theme.deep
        border.color: control.checked || control.visualFocus ? Theme.glow : Theme.edge
        border.width: control.visualFocus ? 2 : 1
        Rectangle {
            x: control.checked ? 17 : 3
            y: 3
            width: 14
            height: 14
            radius: 7
            color: control.checked ? Theme.glow : Theme.subtext
            Behavior on x { NumberAnimation { duration: Theme.duration; easing.type: Theme.reduceMotion ? Easing.Linear : Easing.OutBack; easing.overshoot: 1.2 } }
            Behavior on color { ColorAnimation { duration: Theme.duration } }
        }
        Behavior on color { ColorAnimation { duration: Theme.duration } }
    }
    contentItem: Item {}
}
