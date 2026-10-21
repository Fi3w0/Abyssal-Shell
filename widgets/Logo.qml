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
    // The builtin mark's ink sits ~3.7% left and ~1.8% high of its viewBox
    // centre, so the drawn pill looked lopsided. Nudge the artwork instead.
    readonly property bool builtinMark: (opts.icon || "builtin:logo") === "builtin:logo"
    readonly property real visualOffsetX: builtinMark ? Math.round(iconPx * 0.037) : 0
    readonly property real visualOffsetY: builtinMark ? Math.round(iconPx * 0.018) : 0

    implicitWidth: Math.max(28, iconPx + 14)
    implicitHeight: Math.max(28, iconPx + 8)

    CustomIcon {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.visualOffsetX
        anchors.verticalCenterOffset: root.visualOffsetY
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
