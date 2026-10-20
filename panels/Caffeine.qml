import QtQuick
import Quickshell
import Quickshell.Wayland

// Keeps the session awake while Shell.caffeine is on. An idle inhibitor
// needs a mapped surface, so this is a 1×1 transparent one that takes no
// input and only exists while caffeine is on.
PanelWindow {
    id: root

    required property bool active

    visible: active
    WlrLayershell.namespace: "abyssal-caffeine"
    WlrLayershell.layer: WlrLayer.Background
    anchors { top: true; left: true }
    exclusiveZone: 0
    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"
    mask: Region {}

    IdleInhibitor {
        window: root
        enabled: root.active
    }
}
