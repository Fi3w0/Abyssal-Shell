import QtQuick
import "../components"
import "../services"

// Only shows up when the CPU runs hot, like Moonlit.
StatChip {
    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property int threshold: opts.threshold ?? 75

    readonly property bool shown: SystemInfo.cpuTemp > 0 && (opts.display === "always" || SystemInfo.cpuTemp >= threshold)
    vertical: ctx ? ctx.vertical : false
    showIcon: opts.showIcon !== false
    label: opts.showLabel === true ? "CPU" : ""
    icon: "thermometer"
    iconColor: SystemInfo.cpuTemp >= threshold ? Theme.warn : Theme.subtext
    value: Math.round(opts.unit === "f" ? SystemInfo.cpuTemp * 9 / 5 + 32 : SystemInfo.cpuTemp) + (opts.unit === "f" ? "°F" : "°C")
}
