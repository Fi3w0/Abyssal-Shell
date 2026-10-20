import QtQuick
import "../components"
import "../services"

// Lit only while a screen recorder is running.
BarButton {
    property var ctx

    readonly property bool shown: SystemInfo.recording
    icon: "record"
    iconColor: Theme.rose
    onClicked: Notifications.push("Abyssal", "Recording active", "A screen recording app is running", "")
}
