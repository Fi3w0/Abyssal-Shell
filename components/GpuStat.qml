import QtQuick
import "."
import "../services"

StatChip {
    property var ctx
    property bool temperature: false
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property var gpu: GpuStats.device(opts.gpu || "auto")
    readonly property var reading: gpu ? (temperature ? gpu.temperature : gpu.usage) : null
    readonly property bool valid: typeof reading === "number" && Number.isFinite(reading)
    readonly property bool shown: GpuStats.devices.length > 0
    vertical: ctx ? ctx.vertical : false
    icon: temperature ? "thermometer" : "gpu"
    showIcon: opts.showIcon !== false
    label: opts.showLabel !== false ? "GPU" : ""
    value: !valid ? "—" : temperature
        ? Math.round(opts.unit === "f" ? reading * 9 / 5 + 32 : reading) + (opts.unit === "f" ? "°F" : "°C")
        : Math.round(reading) + "%"
    iconColor: valid && reading >= (opts.warning ?? (temperature ? 80 : 90)) ? Theme.warn : Theme.subtext
}
