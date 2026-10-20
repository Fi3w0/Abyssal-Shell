import QtQuick
import "../components"
import "../services"

// Only shows up when the CPU runs hot, like Moonlit.
StatChip {
    property var ctx
    property int threshold: ctx && ctx.options && ctx.options.threshold ? ctx.options.threshold : 75

    readonly property bool shown: SystemInfo.cpuTemp >= threshold
    vertical: ctx ? ctx.vertical : false
    active: true
    icon: "thermometer"
    iconColor: Theme.warn
    value: Math.round(SystemInfo.cpuTemp) + "°"
}
