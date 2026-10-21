pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Abyssal's own idle timer (ext-idle-notify, no idle daemon needed):
// blank the screens after `blank` minutes, lock after `lock` minutes,
// 0 = never. Caffeine pauses both. Stored in ~/.config/abyssal/idle.json.
//
// Blanking is a black overlay that any input removes, not a real power
// off: TideWM's output power toggle is still unverified on hardware.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/abyssal"
    readonly property string path: dir + "/idle.json"
    property var data: ({})
    property bool writable: false

    readonly property int blank: Math.max(0, Number(data.blank) || 0)
    readonly property int lock: Math.max(0, Number(data.lock) || 0)
    readonly property bool configured: blank > 0 || lock > 0
    readonly property bool blanked: blankMonitor.enabled && blankMonitor.isIdle

    function set(key, minutes) {
        if (!writable || (key !== "blank" && key !== "lock")) return
        const next = Object.assign({}, data)
        next[key] = Math.max(0, Math.round(minutes))
        data = next
        if (!directory.running) directory.running = true
    }

    IdleMonitor {
        id: blankMonitor
        enabled: root.blank > 0 && !Shell.caffeine
        timeout: root.blank * 60
        respectInhibitors: true
    }
    IdleMonitor {
        id: lockMonitor
        enabled: root.lock > 0 && !Shell.caffeine
        timeout: root.lock * 60
        respectInhibitors: true
        onIsIdleChanged: if (isIdle) Shell.lock()
    }

    Process {
        id: directory
        command: ["mkdir", "-p", root.dir]
        onExited: (code, status) => {
            if (code === 0) file.setText(JSON.stringify(root.data, null, 2) + "\n")
            else console.warn("abyssal: could not create the idle settings directory")
        }
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text())
                if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw new Error("expected an object")
                root.data = parsed
                root.writable = true
            } catch (e) {
                root.writable = false
                console.warn("abyssal: keeping idle.json unchanged because it is invalid:", e)
            }
        }
        onLoadFailed: err => { root.writable = err === FileViewError.FileNotFound }
    }
}
