import QtQuick
import "../components"
import "../services"

// Opens the wallpaper picker (on every monitor, picking for this one first).
BarButton {
    id: root
    property var ctx

    iconSize: ctx && ctx.options ? (ctx.options.iconSize ?? 17) : 17
    icon: "image"
    active: Shell.wallpaperOn !== ""
    onClicked: Shell.toggleWallpaperPicker(ctx.output)
}
