import QtQuick
import "../components"
import "../services"

// The Abyssal mark; opens the app grid like the launcher widget.
Item {
    id: root
    property var ctx

    implicitWidth: ctx && ctx.vertical ? 32 : 36
    implicitHeight: 30

    Icon {
        anchors.centerIn: parent
        name: "logo"
        size: 20
        stroke: 2.2
        color: area.containsMouse || (root.ctx && Shell.launcherOn === root.ctx.output) ? Theme.accent : Theme.cyan
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Shell.toggleLauncher(root.ctx.output)
    }
}
