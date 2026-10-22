import QtQuick
import QtQuick.Controls as C

C.Slider {
    id: control
    implicitWidth: 180
    implicitHeight: 28 * Theme.density
    live: true
    opacity: enabled ? 1 : 0.5
    background: Rectangle {
        x: control.leftPadding
        y: (control.height - height) / 2
        width: control.availableWidth
        height: 4
        radius: 2
        color: Theme.edge
        Rectangle { width: control.visualPosition * parent.width; height: parent.height; radius: 2; color: Theme.glow }
    }
    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: (control.height - height) / 2
        width: 14
        height: 14
        radius: 7
        color: Theme.text
        border.color: control.visualFocus ? Theme.glow : Theme.crust
        border.width: 2
    }
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home || event.key === Qt.Key_End) {
            value = event.key === Qt.Key_Home ? from : to;
            moved();
            event.accepted = true;
        } else if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
            value = Math.max(from, Math.min(to, value + (event.key === Qt.Key_PageUp ? 10 : -10) * stepSize));
            moved();
            event.accepted = true;
        }
    }
}
