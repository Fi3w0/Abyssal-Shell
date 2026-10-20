import QtQuick
import "../services"

// Square icon button for the bar (Moonlit's TrayBtn).
Item {
    id: root

    property string icon: "square"
    property color  iconColor: Theme.subtext
    property real   iconSize: 17
    property bool   active: false
    property color  hoverColor: Theme.hover
    signal clicked(var mouse)
    signal wheel(var event)

    implicitWidth: 32
    implicitHeight: 32

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.active ? Theme.accentSoft : area.containsMouse ? root.hoverColor : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }

    Icon {
        anchors.centerIn: parent
        name: root.icon
        size: root.iconSize
        color: root.active ? Theme.accent : root.iconColor
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
        onClicked: mouse => root.clicked(mouse)
        onWheel: event => root.wheel(event)
    }
}
