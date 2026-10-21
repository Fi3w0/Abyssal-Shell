import QtQuick
import "../components"
import "../services"

StatChip {
    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    vertical: ctx ? ctx.vertical : false
    icon: "memory"
    showIcon: opts.showIcon !== false
    label: opts.showLabel !== false ? "RAM" : ""
    value: opts.format === "percent" ? Math.round(SystemInfo.ramUsedMb / SystemInfo.ramTotalMb * 100) + "%"
         : (SystemInfo.ramUsedMb / 1024).toFixed(1) + (opts.format === "total" ? "/" + (SystemInfo.ramTotalMb / 1024).toFixed(1) : "") + "G"
}
