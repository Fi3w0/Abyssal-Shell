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
        "launcher":       { file: "Launcher.qml",      name: "Launcher",        cat: "shell",  desc: "Opens the app grid" },
        "logo":           { file: "Logo.qml",          name: "Logo",            cat: "shell",  desc: "Abyssal mark, opens the app grid" },
        "workspaces":     { file: "Workspaces.qml",    name: "Workspaces",      cat: "tidewm", desc: "This monitor’s workspaces" },
        "window-title":   { file: "WindowTitle.qml",   name: "Window title",    cat: "tidewm", desc: "Last window used on this monitor" },
        "task-manager":   { file: "TaskManager.qml",   name: "Task manager",    cat: "tidewm", desc: "Open and pinned apps",
                            options: [{ key: "style", label: "Style", values: [["icons", "Icons only"], ["titles", "Icons + titles"]], default: "icons" },
                                      { key: "scope", label: "Windows", values: [["all", "All monitors"], ["monitor", "This monitor"]], default: "all" }] },
        "clock":          { file: "Clock.qml",         name: "Clock",           cat: "status", desc: "Time, optionally the date",
                            options: [{ key: "date", label: "Date", values: [[false, "Time"], [true, "Time + date"]], default: false }] },
        "ram":            { file: "Ram.qml",           name: "Memory",          cat: "system", desc: "RAM in use" },
        "cpu":            { file: "Cpu.qml",           name: "CPU",             cat: "system", desc: "CPU usage" },
        "temp":           { file: "Temp.qml",          name: "CPU temperature", cat: "system", desc: "Shows up when the CPU runs hot" },
        "battery":        { file: "Battery.qml",       name: "Battery",         cat: "system", desc: "Laptop battery", laptop: true },
        "network":        { file: "Network.qml",       name: "Network",         cat: "status", desc: "Wi-Fi or wired" },
        "bluetooth":      { file: "Bluetooth.qml",     name: "Bluetooth",       cat: "status", desc: "Adapter on or off" },
        "volume":         { file: "Volume.qml",        name: "Volume",          cat: "status", desc: "Click mutes, scroll changes it" },
        "recording":      { file: "Recording.qml",     name: "Recording",       cat: "status", desc: "Lit while a recorder runs" },
        "tray":           { file: "Tray.qml",          name: "System tray",     cat: "status", desc: "App icons and their menus" },
        "quick-settings": { file: "QuickSettings.qml", name: "Quick settings",  cat: "shell",  desc: "Toggles, volume, lock" },
        "power":          { file: "Power.qml",         name: "Power menu",      cat: "shell",  desc: "Lock, log out, sleep, reboot" },
        "separator":      { file: "Separator.qml",     name: "Separator",       cat: "layout", desc: "Thin line inside a group" },
        "spacer":         { file: "",                  name: "Spacer",          cat: "layout", desc: "Pushes groups apart, splits islands" }
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
        return registry[id] && registry[id].options ? registry[id].options : []
    }

    function optionValue(item, opt) {
        return item && item[opt.key] !== undefined ? item[opt.key] : opt.default
    }
}
