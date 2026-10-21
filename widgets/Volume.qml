import QtQuick
import "../components"
import "../services"

// Click opens the Sound page under the widget, middle click mutes, scroll
// changes the volume (the OSD shows the result).
BarButton {
    id: root
    property var ctx

    icon: Audio.muted || Audio.volume === 0 ? "volume-mute" : Audio.volume < 0.5 ? "volume-low" : "volume-high"
    iconColor: Audio.muted ? Theme.overlay : Theme.subtext
    active: Shell.detail !== null && Shell.detail.page === "sound" && Shell.detail.output === (ctx ? ctx.output : "")

    onClicked: mouse => {
        if (mouse.button === Qt.MiddleButton) {
            Audio.toggleMute()
            return
        }
        const p = mapToItem(null, width / 2, height / 2)
        Shell.toggleDetail(ctx.output, ctx.edge, "sound", ctx.vertical ? p.y : p.x, ctx.thickness)
    }
    onWheel: event => {
        const step = Math.max(1, Math.min(20, ctx && ctx.options ? (ctx.options.step ?? 5) : 5)) / 100
        Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? step : -step))
    }
}
