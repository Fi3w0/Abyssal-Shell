import QtQuick
import "../components"
import "../services"

// Opens the launcher on this monitor. Icon and its size are widget options
// (any image, like Plasma's launcher icon).
Item {
    id: root

    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property int thickness: ctx ? ctx.thickness : 42
    readonly property real iconPx: Math.round(thickness * (opts.iconSize || 60) / 100)
    readonly property bool active: ctx ? Shell.launcherOn === ctx.output : false

    implicitWidth: Math.max(28, iconPx + 12)
    implicitHeight: Math.max(28, iconPx + 12)

    Rectangle {
        anchors.fill: parent
        radius: Math.min(12, width / 3)
        color: root.active ? Theme.accentSoft : area.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }

    CustomIcon {
        anchors.centerIn: parent
        spec: root.opts.icon || "builtin:grid"
        size: root.iconPx
        tint: root.active ? Theme.accent : Theme.cyan
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Shell.toggleLauncher(root.ctx.output)
    }
}
