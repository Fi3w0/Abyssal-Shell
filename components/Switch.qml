import QtQuick
import "../services"

// On/off pill: a hairline track, the knob lights up violet when on.
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    implicitWidth: 34
    implicitHeight: 20
    radius: height / 2
    color: checked ? Theme.alpha(Theme.accent, 0.14) : "transparent"
    border.width: 1
    border.color: checked ? Theme.alpha(Theme.accent, 0.55) : Theme.alpha(Theme.text, 0.14)
    Behavior on color { ColorAnimation { duration: Theme.anim } }

    Rectangle {
        width: 12
        height: 12
        radius: 6
        y: 3
        x: root.checked ? root.width - width - 3 : 3
        color: root.checked ? Theme.accent : Theme.overlay
        Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
