import QtQuick
import "../components"
import "../services"

// Opens the app grid on this monitor.
BarButton {
    property var ctx

    readonly property int size: ctx ? ctx.thickness : 42
    implicitWidth: Math.max(32, size - 10)
    implicitHeight: Math.max(32, size - 10)
    icon: "grid"
    iconSize: Math.round(Math.max(16, Math.min(28, size * 0.42)))
    iconColor: Theme.cyan
    active: ctx ? Shell.launcherOn === ctx.output : false
    onClicked: Shell.toggleLauncher(ctx.output)
}
