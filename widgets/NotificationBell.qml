import QtQuick
import "../components"
import "../services"

// Opens the notification centre under the widget. A rose dot means unread
// notifications; the bell is crossed out during Do not disturb.
BarButton {
    id: root
    property var ctx

    iconSize: ctx && ctx.options ? (ctx.options.iconSize ?? 17) : 17
    icon: Notifications.dnd ? "bell-off" : "bell"
    iconColor: Notifications.dnd ? Theme.rose : Theme.subtext
    active: Shell.detail !== null && Shell.detail.page === "notifications" && Shell.detail.output === (ctx ? ctx.output : "")
    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
            Notifications.dnd = !Notifications.dnd
            return
        }
        const p = mapToItem(null, width / 2, height / 2)
        Shell.toggleDetail(ctx.output, ctx.edge, "notifications", ctx.vertical ? p.y : p.x, ctx.thickness)
    }

    Rectangle {
        visible: Notifications.unread > 0 && !Notifications.dnd
        anchors { right: parent.right; top: parent.top; margins: 6 }
        width: 6
        height: 6
        radius: 3
        color: Theme.rose
    }
}
