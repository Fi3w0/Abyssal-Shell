import QtQuick
import QtQuick.Layouts
import "../services"

// Small spaced caps label with a hairline running to the right edge.
RowLayout {
    id: root

    property string text: ""
    // Spinning ring after the label (scanning).
    property bool busy: false

    spacing: 8
    Layout.fillWidth: true
    Layout.topMargin: 8

    Text {
        text: root.text.toUpperCase()
        color: Theme.overlay
        font { family: Theme.font; pixelSize: 9; letterSpacing: 1.6 }
    }
    Rectangle {
        visible: root.busy
        implicitWidth: 8
        implicitHeight: 8
        radius: 4
        color: "transparent"
        border { width: 1; color: Theme.cyan }
        Rectangle { width: 4; height: 4; color: Theme.glassStrong; anchors { right: parent.right; top: parent.top } }
        RotationAnimation on rotation { running: root.busy; from: 0; to: 360; duration: 1200; loops: Animation.Infinite }
    }
    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 1
        color: Theme.hairline
    }
}
