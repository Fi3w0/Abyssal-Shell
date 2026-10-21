import QtQuick
import "../components"
import "../services"

// Opens the quick settings panel next to this bar.
BarButton {
    property var ctx
    iconSize: ctx && ctx.options ? (ctx.options.iconSize ?? 17) : 17

    icon: "sliders"
    active: ctx ? Shell.quickSettings !== null && Shell.quickSettings.output === ctx.output : false
    onClicked: Shell.toggleQuickSettings(ctx.output, ctx.edge)
}
