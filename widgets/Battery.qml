import QtQuick
import "../components"
import "../services"

// Laptop only: hidden when UPower reports no laptop battery.
StatChip {
    property var ctx

    readonly property bool shown: SystemInfo.hasBattery
    vertical: ctx ? ctx.vertical : false
    icon: SystemInfo.charging ? "battery-charging" : SystemInfo.batteryPct <= 20 ? "battery-low" : "battery"
    iconColor: SystemInfo.charging ? Theme.success : SystemInfo.batteryPct <= 20 ? Theme.danger : Theme.subtext
    value: SystemInfo.batteryPct + "%"
}
