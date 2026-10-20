import QtQuick
import "../components"
import "../services"

StatChip {
    property var ctx

    vertical: ctx ? ctx.vertical : false
    icon: SystemInfo.netType === "wifi" ? "wifi" : SystemInfo.netType === "ethernet" ? "ethernet" : "wifi-off"
    iconColor: SystemInfo.netType === "" ? Theme.overlay : Theme.cyan
    // Vertical bars have no room for the network name: signal or nothing.
    value: SystemInfo.netType === "" ? (vertical ? "" : "Offline")
         : SystemInfo.netType === "ethernet" ? (vertical ? "" : "Wired")
         : vertical ? SystemInfo.wifiSignal + "%" : SystemInfo.netName
}
