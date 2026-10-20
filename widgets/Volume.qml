import QtQuick
import "../components"
import "../services"

// Click mutes, scroll changes the volume (the OSD shows the result).
BarButton {
    property var ctx

    icon: Audio.muted || Audio.volume === 0 ? "volume-mute" : Audio.volume < 0.5 ? "volume-low" : "volume-high"
    iconColor: Audio.muted ? Theme.overlay : Theme.subtext

    onClicked: Audio.toggleMute()
    onWheel: event => Audio.setVolume(Audio.volume + (event.angleDelta.y > 0 ? 0.05 : -0.05))
}
