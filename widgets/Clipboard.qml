import QtQuick
import "../components"
import "../services"

// Opens the clipboard history under the widget.
BarButton {
    id: root
    property var ctx

    iconSize: ctx && ctx.options ? (ctx.options.iconSize ?? 17) : 17
    icon: "clipboard"
    active: Shell.detail !== null && Shell.detail.page === "clipboard" && Shell.detail.output === (ctx ? ctx.output : "")
    onClicked: {
        const p = mapToItem(null, width / 2, height / 2)
        Shell.toggleDetail(ctx.output, ctx.edge, "clipboard", ctx.vertical ? p.y : p.x, ctx.thickness)
    }
}
