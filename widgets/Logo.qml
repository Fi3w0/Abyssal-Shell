import QtQuick
import "../components"
import "../services"

// The Abyssal mark, or any image you pick (distro logo, avatar…), at a size
// relative to the panel. Opens the launcher like the launcher widget.
Item {
    id: root

    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property int thickness: ctx ? ctx.thickness : 42
    readonly property real iconPx: Math.round(thickness * (opts.iconSize || 50) / 100)
    readonly property bool active: ctx ? Shell.launcherOn === ctx.output : false

    implicitWidth: Math.max(28, iconPx + 14)
    implicitHeight: Math.max(28, iconPx + 8)

    CustomIcon {
        anchors.centerIn: parent
        spec: root.opts.icon || "builtin:logo"
        size: root.iconPx
        tint: area.containsMouse || root.active ? Theme.accent : Theme.cyan
        scale: area.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 90 } }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Shell.toggleLauncher(root.ctx.output)
    }
}
