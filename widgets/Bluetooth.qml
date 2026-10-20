import QtQuick
import Quickshell.Bluetooth
import "../components"
import "../services"

// Until the Bluetooth panel exists, a click toggles the adapter.
BarButton {
    property var ctx
    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property bool shown: adapter !== null
    icon: "bluetooth"
    iconColor: adapter && adapter.enabled ? Theme.cyan : Theme.overlay
    onClicked: if (adapter) adapter.enabled = !adapter.enabled
}
