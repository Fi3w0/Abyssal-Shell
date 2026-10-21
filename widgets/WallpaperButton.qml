import QtQuick
import "../components"
import "../services"

// Opens the wallpaper picker on this panel's monitor.
BarButton {
    id: root
    property var ctx

    iconSize: ctx && ctx.options ? (ctx.options.iconSize ?? 17) : 17
    icon: "image"
    active: Shell.wallpaperOn !== "" && Shell.wallpaperOn === (ctx ? ctx.output : "")
    onClicked: Shell.toggleWallpaperPicker(ctx.output)
}
