import QtQuick
import Quickshell.Bluetooth
import "../components"
import "../services"

// Click opens the Bluetooth page under the widget; right click turns the
// adapter on or off.
BarButton {
    id: root
    property var ctx
    iconSize: ctx && ctx.options ? (ctx.options.iconSize ?? 17) : 17
    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool shown: adapter !== null
    icon: "bluetooth"
    iconColor: adapter && adapter.enabled ? Theme.cyan : Theme.overlay
    active: Shell.detail !== null && Shell.detail.page === "bluetooth" && Shell.detail.output === (ctx ? ctx.output : "")
    onClicked: mouse => {
        if (mouse.button === Qt.RightButton) {
            if (adapter) adapter.enabled = !adapter.enabled
            return
        }
        const p = mapToItem(null, width / 2, height / 2)
        Shell.toggleDetail(ctx.output, ctx.edge, "bluetooth", ctx.vertical ? p.y : p.x, ctx.thickness)
    }
}
