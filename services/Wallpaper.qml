pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtQml.Models

// Animated wallpaper per monitor, started with the shell so it follows
// TideWM's session instead of a separate launcher script.
//
// ~/.config/abyssal/wallpaper.json:
// {
//   "screens": {
//     "DP-4":     { "video": "/path/to/video.mp4", "hwdec": "nvdec-copy" },
//     "HDMI-A-2": { "video": "/path/to/video.mp4" },
//     "*":        { "video": "/path/to/fallback.mp4" }
//   }
// }
//
// `video` and `image` are both accepted (mpvpaper plays either); `hwdec`
// defaults to `auto`; `fit` is "crop" (fill the screen, cut the overflow,
// like the picker's preview; the default) or "fit" (whole picture, bars);
// `options` appends raw mpv options. Outputs are
// matched by name at runtime, so hotplug and other monitors work without
// editing code.
Singleton {
    id: root

    readonly property string dir: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/abyssal"
    readonly property string path: dir + "/wallpaper.json"
    readonly property string socketDir: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"

    property var config: ({})
    // A fresh shell must not add to players left by a previous one: stop the
    // old ones first, then start one per output.
    property bool ready: false

    readonly property var entries: {
        const configured = root.config && root.config.screens ? root.config.screens : ({})
        const out = []
        for (const screen of Quickshell.screens) {
            const entry = configured[screen.name] || configured["*"]
            if (!entry) continue
            const source = entry.video || entry.image || ""
            if (!source) continue
            out.push({
                key: [screen.name, source, entry.hwdec || "auto", entry.options || "", entry.fit || "crop"].join("\n"),
                output: screen.name,
                source: source,
                hwdec: entry.hwdec || "auto",
                fit: entry.fit === "fit" ? "fit" : "crop",
                options: entry.options || ""
            })
        }
        return out
    }

    // ── For the wallpaper picker ────────────────────────────────────────
    // What is on `output` now ("" for nothing).
    function currentFor(output) {
        const screens = config && config.screens ? config.screens : {}
        const e = screens[output] || screens["*"]
        return e ? (e.video || e.image || "") : ""
    }

    // Puts `path` on `output`, keeping that output's hwdec and options.
    function apply(output, path, kind) {
        const next = JSON.parse(JSON.stringify(config || {}))
        next.version = next.version || 1
        next.screens = next.screens || {}
        const old = next.screens[output] || {}
        const entry = { hwdec: old.hwdec || "auto" }
        if (old.options) entry.options = old.options
        if (old.fit) entry.fit = old.fit
        entry[kind === "image" ? "image" : "video"] = path
        next.screens[output] = entry
        write(next)
    }

    // Extra folders the picker lists besides <Pictures>/wallpapers.
    readonly property var folders: config && Array.isArray(config.folders) ? config.folders : []
    function addFolder(dir) {
        if (folders.includes(dir)) return
        const next = JSON.parse(JSON.stringify(config || {}))
        next.folders = folders.concat([dir])
        write(next)
    }

    function write(next) {
        config = next
        pendingText = JSON.stringify(next, null, 1) + "\n"
        if (!mkdir.running) mkdir.running = true
    }
    property string pendingText: ""
    Process {
        id: mkdir
        command: ["mkdir", "-p", root.dir]
        onExited: code => { if (code === 0) file.setText(root.pendingText) }
    }

    // Wallpapers with thumbnails and palettes, from scripts/wall-index.
    property var index: []
    property bool scanning: indexer.running
    function scan() {
        if (indexer.running) return
        indexer.command = [Quickshell.shellPath("scripts/wall-index")].concat(
            folders.length ? root.defaultFolders.concat(folders) : [])
        indexer.running = true
    }
    // Passed along with extra folders, so those add to the defaults.
    readonly property var defaultFolders: [picturesDir + "/wallpapers", picturesDir + "/Wallpapers"]
    property string picturesDir: Quickshell.env("HOME") + "/Pictures"
    Process {
        running: true
        command: ["sh", "-c", "xdg-user-dir PICTURES 2>/dev/null"]
        stdout: StdioCollector { onStreamFinished: { const d = text.trim(); if (d && d !== Quickshell.env("HOME")) root.picturesDir = d } }
    }
    Process {
        id: indexer
        stdout: StdioCollector {
            onStreamFinished: { try { root.index = JSON.parse(text) } catch (e) { console.warn("abyssal: wall-index output:", e) } }
        }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) console.warn(text.trim()) }
    }

    FileView {
        id: file
        preload: false
        blockLoading: true
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.config = JSON.parse(text())
            } catch (e) {
                console.warn("abyssal: wallpaper.json is not valid JSON, keeping the running wallpapers:", e)
            }
        }
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) root.config = ({})
        }
    }

    Component.onCompleted: file.text()

    // One player per output. Recreating a delegate destroys its Process,
    // which Quickshell terminates, so config changes and hotplug restart
    // only the affected output.
    Process {
        id: cleanup
        command: ["pkill", "-f", "input-ipc-server=.*/abyssal-wallpaper-"]
        running: true
        onExited: root.ready = true
    }

    // Keyed, so a change to one output's entry restarts only that player.
    ScriptModel {
        id: players
        values: root.ready ? root.entries : []
        objectProp: "key"
    }
    Instantiator {
        model: players
        delegate: Component {
        QtObject {
            id: player
            required property var modelData

            readonly property string socket: root.socketDir + "/abyssal-wallpaper-" + modelData.output + ".sock"

            property Process process: Process {
                running: false
                command: [
                    "mpvpaper", "-p", "-o",
                    "hwdec=" + player.modelData.hwdec
                        + " loop-file=inf no-audio terminal=no cache=no demuxer-readahead-secs=0"
                        + (player.modelData.fit === "crop" ? " panscan=1.0" : "")
                        + (player.modelData.options ? " " + player.modelData.options : "")
                        + " input-ipc-server=" + player.socket,
                    player.modelData.output, player.modelData.source
                ]
            }

            // modelData is assigned after creation; start once it is there.
            property Timer starter: Timer {
                interval: 0
                running: true
                onTriggered: player.process.running = true
            }
        }
        }
    }

}
