import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../components"
import "../services"

// StatusNotifier tray. Left/right click opens the app's menu (or activates
// it when it has none), middle click activates.
Grid {
    id: root

    property var ctx
    readonly property bool vertical: ctx ? ctx.vertical : false
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property int iconSize: opts.iconSize ?? 18

    rows: vertical ? -1 : 1
    columns: vertical ? 1 : -1
    spacing: opts.spacing ?? 3
    readonly property bool shown: repeater.count > 0

    Repeater {
        id: repeater
        model: SystemTray.items

        delegate: Item {
            id: entry
            required property var modelData

            implicitWidth: Math.max(28, root.iconSize + 10)
            implicitHeight: Math.max(28, root.iconSize + 10)

            Rectangle {
                anchors.fill: parent
                radius: 8
                color: area.containsMouse || menu.visible ? Theme.hover : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.anim } }
            }

            HiDpiIcon {
                id: icon
                anchors.centerIn: parent
                implicitSize: root.iconSize
                asynchronous: true
                source: entry.modelData.icon
                visible: status === Image.Ready
            }
            Icon {
                anchors.centerIn: parent
                visible: !icon.visible
                name: "app"
                size: 15
                color: Theme.subtext
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: mouse => {
                    if (mouse.button === Qt.MiddleButton || !entry.modelData.hasMenu) {
                        entry.modelData.activate()
                        return
                    }
                    menu.visible = !menu.visible
                }
            }

            TrayMenu {
                id: menu
                handle: entry.modelData.menu
                anchor.item: entry
                anchor.edges: root.ctx.edge === "bottom" ? Edges.Top
                            : root.ctx.edge === "left" ? Edges.Right
                            : root.ctx.edge === "right" ? Edges.Left
                            : Edges.Bottom
                anchor.gravity: root.ctx.edge === "bottom" ? Edges.Top | Edges.Left
                              : root.ctx.edge === "left" ? Edges.Right | Edges.Bottom
                              : root.ctx.edge === "right" ? Edges.Left | Edges.Bottom
                              : Edges.Bottom | Edges.Left
                anchor.margins.top: root.ctx.edge === "top" ? 8 : 0
                anchor.margins.bottom: root.ctx.edge === "bottom" ? 8 : 0
                anchor.margins.left: root.ctx.edge === "left" ? 8 : 0
                anchor.margins.right: root.ctx.edge === "right" ? 8 : 0
            }
        }
    }
}
