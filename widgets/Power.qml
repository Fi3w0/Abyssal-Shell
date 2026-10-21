import QtQuick
import "../components"
import "../services"

BarButton {
    property var ctx
    iconSize: ctx && ctx.options ? (ctx.options.iconSize ?? 17) : 17

    icon: "power"
    iconColor: Theme.danger
    active: ctx ? Shell.powerOn === ctx.output : false
    onClicked: Shell.togglePower(ctx.output)
}
