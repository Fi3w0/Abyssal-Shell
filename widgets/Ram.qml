import QtQuick
import "../components"
import "../services"

StatChip {
    property var ctx
    vertical: ctx ? ctx.vertical : false
    icon: "memory"
    label: "RAM"
    value: (SystemInfo.ramUsedMb / 1024).toFixed(1) + "G"
}
