import QtQuick
import "../services"

// 0..1 slider, quick-menu style: a 3px hairline track with a violet to
// cyan fill and a small knob. Drag or click to set, scroll to nudge 5%.
Item {
    id: root

    property real value: 0
    signal moved(real value)

    implicitHeight: 18
    implicitWidth: 160

    function setFrom(x) {
        root.moved(Math.max(0, Math.min(1, x / width)))
    }

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 3
        radius: 2
        color: Theme.alpha(Theme.text, 0.10)

        Rectangle {
            width: Math.max(height, parent.width * root.value)
            height: parent.height
            radius: 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: Theme.accent }
                GradientStop { position: 1; color: Theme.cyan }
            }
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(root.width - width, root.width * root.value - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 11
        height: 11
        radius: 6
        color: Theme.text
        border.width: area.containsMouse || area.pressed ? 3 : 0
        border.color: Theme.alpha(Theme.cyan, 0.45)
        Behavior on border.width { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFrom(mouse.x - 6)
        onPositionChanged: mouse => { if (pressed) root.setFrom(mouse.x - 6) }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
