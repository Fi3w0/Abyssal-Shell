import QtQuick
import "../components"
import "../services"

// Lit only while a screen recorder is running.
BarButton {
    property var ctx

    readonly property bool shown: SystemInfo.recording || (ctx && ctx.options && ctx.options.always === true)
    icon: "record"
    iconColor: SystemInfo.recording ? Theme.rose : Theme.overlay
    onClicked: Notifications.push("Abyssal", "Recording active", "A screen recording app is running", "")
}
