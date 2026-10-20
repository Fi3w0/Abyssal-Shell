import QtQuick
import "../components"
import "../services"

BarButton {
    property var ctx

    icon: "power"
    iconColor: Theme.danger
    active: ctx ? Shell.powerOn === ctx.output : false
    onClicked: Shell.togglePower(ctx.output)
}
