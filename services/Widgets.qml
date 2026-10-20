pragma Singleton

import QtQuick
import Quickshell

// Every widget a bar can hold. The edit mode's widget drawer lists these;
// `available` false greys a widget out there and hides it on the bar.
Singleton {
    id: root

    readonly property var registry: ({
        "logo":         { file: "Logo.qml",        name: "Logo" },
        "workspaces":   { file: "Workspaces.qml",  name: "Workspaces" },
        "window-title": { file: "WindowTitle.qml", name: "Window title" },
        "clock":        { file: "Clock.qml",       name: "Clock" },
        "ram":          { file: "Ram.qml",         name: "Memory" },
        "cpu":          { file: "Cpu.qml",         name: "CPU" },
        "temp":         { file: "Temp.qml",        name: "CPU temperature" },
        "battery":      { file: "Battery.qml",     name: "Battery", laptop: true },
        "network":      { file: "Network.qml",     name: "Network" },
        "recording":    { file: "Recording.qml",   name: "Recording indicator" },
        "bluetooth":    { file: "Bluetooth.qml",   name: "Bluetooth" },
        "volume":       { file: "Volume.qml",      name: "Volume" },
        "tray":         { file: "Tray.qml",        name: "System tray" },
        "quick-settings": { file: "QuickSettings.qml", name: "Quick settings" },
        "power":        { file: "Power.qml",       name: "Power menu" },
        "separator":    { file: "Separator.qml",   name: "Separator" }
    })

    function url(id) {
        const w = registry[id]
        return w ? Qt.resolvedUrl("../widgets/" + w.file) : ""
    }

    function available(id) {
        const w = registry[id]
        if (!w) return false
        if (w.laptop) return SystemInfo.hasBattery
        return true
    }
}
