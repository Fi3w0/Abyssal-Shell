import QtQuick
import "../components"
import "../services"

// Click opens the Wi-Fi page under the widget.
StatChip {
    id: root
    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})

    vertical: ctx ? ctx.vertical : false
    showIcon: opts.showIcon !== false
    icon: SystemInfo.netType === "wifi" ? "wifi" : SystemInfo.netType === "ethernet" ? "ethernet" : "wifi-off"
    iconColor: SystemInfo.netType === "" ? Theme.overlay : Theme.cyan
    badge: Vpn.on ? "shield-check" : ""
    // Vertical bars have no room for the network name: signal or nothing.
    value: opts.detail === "compact" ? "" : SystemInfo.netType === "" ? (vertical ? "" : "Offline")
         : SystemInfo.netType === "ethernet" ? (vertical ? "" : "Wired")
         : vertical || opts.detail === "signal" ? SystemInfo.wifiSignal + "%" : SystemInfo.netName

    onClicked: {
        const p = mapToItem(null, width / 2, height / 2)
        Shell.toggleDetail(ctx.output, ctx.edge, "wifi", ctx.vertical ? p.y : p.x, ctx.thickness)
    }
}
