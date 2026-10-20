import QtQuick
import "../components"
import "../services"

StatChip {
    property var ctx
    vertical: ctx ? ctx.vertical : false
    icon: "cpu"
    label: "CPU"
    value: SystemInfo.cpuPct + "%"
}
