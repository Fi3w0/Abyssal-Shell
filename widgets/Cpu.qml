import QtQuick
import "../components"
import "../services"

StatChip {
    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    vertical: ctx ? ctx.vertical : false
    icon: "cpu"
    showIcon: opts.showIcon !== false
    label: opts.showLabel !== false ? "CPU" : ""
    valueColor: SystemInfo.cpuPct >= (opts.warning ?? 90) ? Theme.warn : Theme.text
    value: SystemInfo.cpuPct + "%"
}
