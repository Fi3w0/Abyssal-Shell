import QtQuick
import "../services"

// 0..1 slider: track, accent fill, round handle. Drag or click to set,
// scroll to nudge by 5%.
Item {
    id: root

    property real value: 0
    property color fill: Theme.accent
    signal moved(real value)

    implicitHeight: 20
    implicitWidth: 200

    function setFrom(x) {
        root.moved(Math.max(0, Math.min(1, x / width)))
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.alpha(Theme.text, 0.10)

        Rectangle {
            width: Math.max(height, parent.width * root.value)
            height: parent.height
            radius: 3
            color: root.fill
        }
    }

    Rectangle {
        x: Math.max(0, Math.min(root.width - width, root.width * root.value - width / 2))
        anchors.verticalCenter: parent.verticalCenter
        width: 16
        height: 16
        radius: 8
        color: Theme.text
        border.width: 3
        border.color: root.fill
        scale: area.pressed ? 1.15 : 1
        Behavior on scale { NumberAnimation { duration: 120 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.setFrom(mouse.x - 6)
        onPositionChanged: mouse => { if (pressed) root.setFrom(mouse.x - 6) }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.05 : -0.05))))
    }
}
