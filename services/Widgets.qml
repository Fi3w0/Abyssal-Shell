pragma Singleton

import QtQuick
import Quickshell

// Every widget a panel can hold. Any widget works on any panel (taskbar,
// top bar, dock, vertical); how that looks is the user's call. The edit
// mode's sidebar lists these; `available` false greys a widget out there and
// hides it on the panel. `options` are edited by clicking the widget in edit
// mode: [{ key, label, values: [[value, label], ...], default }].
Singleton {
    id: root

    readonly property var categories: [
        ["all", "All"], ["tidewm", "TideWM"], ["system", "System"], ["status", "Status"],
        ["shell", "Shell"], ["layout", "Layout"]
    ]

    readonly property var registry: ({
        "launcher":       { file: "Launcher.qml",      name: "Launcher",        icon: "grid", cat: "shell",  desc: "Opens the launcher",
                            options: [{ key: "icon", label: "Icon", values: [["builtin:logo", "Trench currents"], ["builtin:manta", "Manta"], ["builtin:logo-line", "Original waves"], ["builtin:undertow", "Undertow"], ["builtin:grid", "Grid"]], default: "builtin:grid" },
                                      { key: "iconSize", label: "Size", values: [[40, "40%"], [50, "50%"], [60, "60%"], [75, "75%"], [90, "90%"]], default: 60 }] },
        "logo":           { file: "Logo.qml",          name: "Logo",            icon: "logo", cat: "shell",  desc: "Abyssal mark or any image, opens the launcher",
                            options: [{ key: "icon", label: "Icon", values: [["builtin:logo", "Trench currents"], ["builtin:manta", "Manta"], ["builtin:logo-line", "Original waves"], ["builtin:undertow", "Undertow"], ["builtin:grid", "Grid"]], default: "builtin:logo" },
                                      { key: "iconSize", label: "Size", values: [[40, "40%"], [50, "50%"], [60, "60%"], [75, "75%"], [90, "90%"]], default: 50 }] },
        "workspaces":     { file: "Workspaces.qml",    name: "Workspaces",      icon: "workspaces", cat: "tidewm", desc: "This monitor’s workspaces" },
        "window-title":   { file: "WindowTitle.qml",   name: "Window title",    icon: "window-title", cat: "tidewm", desc: "Last window used on this monitor" },
        "task-manager":   { file: "TaskManager.qml",   name: "Task manager",    icon: "task-manager", cat: "tidewm", desc: "Open and pinned apps",
                            options: [{ key: "style", label: "Style", values: [["icons", "Icons only"], ["titles", "Icons + titles"]], default: "icons" },
                                      { key: "scope", label: "Windows", values: [["all", "All monitors"], ["monitor", "This monitor"]], default: "all" }] },
        "clock":          { file: "Clock.qml",         name: "Clock",           icon: "clock", cat: "status", desc: "Time, optionally the date",
                            options: [{ key: "date", label: "Date", values: [[false, "Time"], [true, "Time + date"]], default: false }] },
        "ram":            { file: "Ram.qml",           name: "Memory",          icon: "memory", cat: "system", desc: "RAM in use" },
        "cpu":            { file: "Cpu.qml",           name: "CPU",             icon: "cpu", cat: "system", desc: "CPU usage" },
        "temp":           { file: "Temp.qml",          name: "CPU temperature", icon: "thermometer", cat: "system", desc: "Shows up when the CPU runs hot" },
        "gpu":            { file: "Gpu.qml",           name: "GPU usage",       icon: "gpu", cat: "system", desc: "Usage of a selected graphics device" },
        "gpu-temp":       { file: "GpuTemp.qml",       name: "GPU temperature", icon: "thermometer", cat: "system", desc: "Temperature of a selected graphics device" },
        "battery":        { file: "Battery.qml",       name: "Battery",         icon: "battery", cat: "system", desc: "Laptop battery", laptop: true },
        "network":        { file: "Network.qml",       name: "Network",         icon: "wifi", cat: "status", desc: "Wi-Fi or wired" },
        "keyboard-layout":{ file: "Layout.qml",        name: "Keyboard layout", icon: "keyboard", cat: "status", desc: "Input language; click cycles, scroll steps" },
        "bluetooth":      { file: "Bluetooth.qml",     name: "Bluetooth",       icon: "bluetooth", cat: "status", desc: "Devices and pairing" },
        "notifications":  { file: "NotificationBell.qml", name: "Notifications", icon: "bell", cat: "status", desc: "Notification centre, unread dot" },
        "clipboard":      { file: "Clipboard.qml",     name: "Clipboard",       icon: "clipboard", cat: "status", desc: "Clipboard history" },
        "volume":         { file: "Volume.qml",        name: "Volume",          icon: "volume-high", cat: "status", desc: "Click mutes, scroll changes it" },
        "recording":      { file: "Recording.qml",     name: "Recording",       icon: "record", cat: "status", desc: "Lit while a recorder runs" },
        "tray":           { file: "Tray.qml",          name: "System tray",     icon: "tray", cat: "status", desc: "App icons and their menus" },
        "quick-settings": { file: "QuickSettings.qml", name: "Quick settings",  icon: "sliders", cat: "shell",  desc: "Toggles, volume, lock" },
        "power":          { file: "Power.qml",         name: "Power menu",      icon: "power", cat: "shell",  desc: "Lock, log out, sleep, reboot" },
        "separator":      { file: "Separator.qml",     name: "Separator",       icon: "separator", cat: "layout", desc: "Thin line inside a group" },
        "spacer":         { file: "",                  name: "Spacer",          icon: "spacer", cat: "layout", desc: "Pushes groups apart, splits islands" }
    })

    function url(id) {
        const w = registry[id]
        return w && w.file ? Qt.resolvedUrl("../widgets/" + w.file) : ""
    }

    function name(id) {
        return registry[id] ? registry[id].name : id
    }

    function available(id) {
        const w = registry[id]
        if (!w) return false
        if (w.laptop) return SystemInfo.hasBattery
        return true
    }

    function options(id) {
        const base = ((registry[id] || {}).options || []).map(o => Object.assign({ type: "choice" }, o))
        const choice = (key, label, values, value) => ({ key: key, label: label, type: "choice", values: values, default: value })
        const toggle = (key, label, value) => choice(key, label, [[true, "Show"], [false, "Hide"]], value)
        const numeric = (key, label, min, max, value, unit) => ({ key: key, label: label, type: "number", minimum: min, maximum: max, default: value, unit: unit || "" })
        const stat = [toggle("showIcon", "Icon", true), toggle("showLabel", "Label", true)]
        let extra = []
        if (id === "logo" || id === "launcher") {
            base[0].type = "icon"
            Object.assign(base[1], { type: "number", minimum: 20, maximum: 100, unit: "%" })
        } else if (id === "cpu") {
            extra = stat.concat([numeric("warning", "Warn above", 1, 100, 90, "%")])
        } else if (id === "temp") {
            extra = [choice("display", "Display", [["hot", "When hot"], ["always", "Always"]], "hot"),
                numeric("threshold", "Hot above", 0, 120, 75, "°C"),
                choice("unit", "Units", [["c", "Celsius"], ["f", "Fahrenheit"]], "c"),
                toggle("showIcon", "Icon", true), toggle("showLabel", "Label", false)]
        } else if (id === "gpu" || id === "gpu-temp") {
            extra = [{ key: "gpu", label: "Device", type: "gpu", default: "auto" }].concat(stat,
                [numeric("warning", "Warn above", 1, id === "gpu" ? 100 : 120, id === "gpu" ? 90 : 80, id === "gpu" ? "%" : "°C")])
            if (id === "gpu-temp") extra.push(choice("unit", "Units", [["c", "Celsius"], ["f", "Fahrenheit"]], "c"))
        } else if (id === "ram") {
            extra = stat.concat([choice("format", "Readout", [["used", "Used (GiB)"], ["total", "Used / total"], ["percent", "Percent"]], "used")])
        } else if (id === "battery") {
            extra = [toggle("showIcon", "Icon", true), toggle("showPercent", "Percentage", true),
                choice("hideFull", "When full", [[false, "Keep showing"], [true, "Hide"]], false),
                numeric("low", "Low below", 5, 50, 20, "%")]
        } else if (id === "clock") {
            extra = [choice("hour24", "Time", [[true, "24-hour"], [false, "12-hour"]], true),
                toggle("seconds", "Seconds", false), toggle("showIcon", "Icon", true),
                choice("dateFormat", "Date style", [["dd/MM/yyyy", "Day / month / year"], ["yyyy-MM-dd", "Year-month-day"], ["ddd d MMM", "Weekday and month"]], "dd/MM/yyyy"),
                choice("opens", "Click opens", [["both", "Calendar + notifications"], ["calendar", "Calendar only"]], "both")]
        } else if (id === "network") {
            extra = [toggle("showIcon", "Icon", true), choice("detail", "Readout", [["name", "Network name"], ["signal", "Signal strength"], ["compact", "Icon only"]], "name")]
        } else if (id === "volume") {
            extra = [numeric("step", "Scroll step", 1, 20, 5, "%")]
        } else if (id === "recording") {
            extra = [choice("always", "Display", [[false, "While recording"], [true, "Always"]], false)]
        } else if (["power", "quick-settings", "bluetooth", "notifications", "clipboard"].includes(id)) {
            extra = [numeric("iconSize", "Icon size", 14, 26, 17, "px")]
        } else if (id === "task-manager") {
            extra = [numeric("iconSize", "Icon size", 30, 90, 60, "%"), numeric("spacing", "Spacing", 0, 24, 6, "px")]
        } else if (id === "tray") {
            extra = [numeric("iconSize", "Icon size", 14, 28, 18, "px"), numeric("spacing", "Spacing", 0, 16, 3, "px")]
        } else if (id === "workspaces") {
            extra = [numeric("minimum", "Minimum", 1, 20, 5, ""), toggle("numbers", "Numbers", false)]
        } else if (id === "window-title") {
            extra = [toggle("showIcon", "Icon", true), numeric("maxWidth", "Max width", 80, 600, 300, "px")]
        } else if (id === "separator") {
            extra = [numeric("thickness", "Thickness", 1, 4, 1, "px"), numeric("length", "Length", 8, 40, 18, "px")]
        } else if (id === "spacer") {
            extra = [numeric("gap", "Minimum gap", 0, 200, 10, "px")]
        }
        const common = id === "spacer" ? [] : [choice("enabled", "Visibility", [[true, "Visible"], [false, "Hidden"]], true)]
        return base.concat(extra, common)
    }

    function optionValue(item, opt) {
        return item && item[opt.key] !== undefined ? item[opt.key] : opt.default
    }
}
