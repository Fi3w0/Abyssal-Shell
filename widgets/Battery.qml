import QtQuick
import "../components"
import "../services"

// Laptop only: hidden when UPower reports no laptop battery.
StatChip {
    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property int low: opts.low ?? 20

    readonly property bool shown: SystemInfo.hasBattery && !(opts.hideFull === true && SystemInfo.batteryPct >= 100)
    vertical: ctx ? ctx.vertical : false
    showIcon: opts.showIcon !== false
    icon: SystemInfo.charging ? "battery-charging" : SystemInfo.batteryPct <= low ? "battery-low" : "battery"
    iconColor: SystemInfo.charging ? Theme.success : SystemInfo.batteryPct <= low ? Theme.danger : Theme.subtext
    value: opts.showPercent !== false ? SystemInfo.batteryPct + "%" : ""
}
