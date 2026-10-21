import QtQuick
import Quickshell
import Quickshell.Wayland
import "../services"

// Black cover over this monitor while Idle has blanked the screens. It
// fades in slowly; any input ends idle and it disappears at once.
PanelWindow {
    id: root

    visible: Idle.blanked || fade.opacity > 0
    WlrLayershell.namespace: "abyssal-blank"
    WlrLayershell.layer: WlrLayer.Overlay
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"

    Rectangle {
        id: fade
        anchors.fill: parent
        color: "black"
        opacity: Idle.blanked ? 1 : 0
        Behavior on opacity {
            enabled: Idle.blanked
            NumberAnimation { duration: 2500; easing.type: Easing.InOutSine }
        }
    }
}
