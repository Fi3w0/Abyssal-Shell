pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Appearance is independent of panel layouts and widget options.
Singleton {
    id: root
    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/abyssal"
    readonly property string path: dir + "/appearance.json"
    property var data: ({})
    property bool writable: false
    readonly property string preset: data.preset === "abyssal-tide" ? "abyssal-tide" : "trench-violet"
    readonly property bool mono: data.mono !== undefined ? data.mono === true : preset === "abyssal-tide"

    function set(key, value) {
        if (!writable) return
        if (key !== "preset" && key !== "mono") return
        if (key === "preset" && value !== "trench-violet" && value !== "abyssal-tide") return
        if (key === "mono" && typeof value !== "boolean") return
        const next = Object.assign({}, data)
        next[key] = value
        data = next
        if (!directory.running) directory.running = true
    }

    Process {
        id: directory
        command: ["mkdir", "-p", root.dir]
        onExited: (code, status) => {
            if (code === 0) file.setText(JSON.stringify(root.data, null, 2) + "\n")
            else console.warn("abyssal: could not create appearance directory")
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
                console.warn("abyssal: keeping appearance.json unchanged because it is invalid:", e)
            }
        }
        onLoadFailed: err => { root.writable = err === FileViewError.FileNotFound }
    }
}
