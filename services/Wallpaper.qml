pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import QtQml.Models
import "../wallpaper" as WallpaperComponents

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
// Videos use mpvpaper; images use awww when available, otherwise Qt. `hwdec`
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
    property var transitionPresets: ({})
    // A fresh shell must not add to players left by a previous one: stop the
    // old ones first, then start one per output.
    property bool ready: false
    property bool awwwAvailable: false
    property bool daemonReady: false
    readonly property bool useAwww: awwwAvailable && config.imageBackend !== "native"
    readonly property string imageBackend: useAwww && daemonReady ? "awww" : "native"
    readonly property string transition: config.transition || "fade"
    readonly property real transitionDuration: typeof config.transitionDuration === "number"
        ? Math.max(0, Math.min(3, config.transitionDuration)) : 0.6

    readonly property var entries: {
        const configured = root.config && root.config.screens ? root.config.screens : ({})
        const out = []
        for (const screen of Quickshell.screens) {
            const entry = configured[screen.name] || configured["*"]
            if (!entry) continue
            const source = entry.video || entry.image || ""
            if (!source) continue
            out.push({
                id: screen.name,
                key: [screen.name, source, entry.hwdec || "auto", entry.options || "", entry.fit || "crop"].join("\n"),
                output: screen.name,
                source: source,
                kind: entry.video ? "video" : "image",
                imageBackend: root.imageBackend,
                transition: root.transition,
                preset: root.config.transitionPreset || "",
                duration: root.transition === "none" ? 0 : root.transitionDuration,
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
    function apply(output, path, kind, preset) {
        const next = JSON.parse(JSON.stringify(config || {}))
        next.version = next.version || 1
        next.screens = next.screens || {}
        const old = next.screens[output] || {}
        const entry = { hwdec: old.hwdec || "auto" }
        if (old.options) entry.options = old.options
        if (old.fit) entry.fit = old.fit
        entry[kind === "image" ? "image" : "video"] = path
        next.screens[output] = entry
        if (preset && transitionPresets[preset]) {
            next.transitionPreset = preset
            next.transition = transitionPresets[preset].type
            next.transitionDuration = transitionPresets[preset].duration
        }
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
    function setOption(key, value) {
        const next = JSON.parse(JSON.stringify(config || {}))
        next[key] = value
        write(next)
    }
    function selectPreset(name) {
        if (!transitionPresets[name]) return
        const next = Object.assign({}, config, {transitionPreset: name,
            transition: transitionPresets[name].type, transitionDuration: transitionPresets[name].duration})
        write(next)
    }
    function setFit(output, fit) {
        const next = JSON.parse(JSON.stringify(config || {}))
        next.screens = next.screens || {}
        next.screens[output] = Object.assign({}, next.screens[output] || next.screens["*"] || {}, {fit: fit})
        write(next)
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

    FileView {
        id: recipes
        path: Quickshell.shellPath("wallpaper/transitions.json")
        blockLoading: true; printErrors: false
        onLoaded: {try {root.transitionPresets = JSON.parse(text())} catch(e) {}}
    }
    Component.onCompleted: { file.text(); recipes.text() }
    IpcHandler {
        target: "wallpaper"
        function preset(name: string): void {root.selectPreset(name)}
        function change(preset: string, path: string, output: string, kind: string): void {
            const target = output || Shell.targetOutput()
            if (Quickshell.screens.some(s => s.name === target)) root.apply(target, path, kind, preset)
        }
    }

    // One player per output. Recreating a delegate destroys its Process,
    // which Quickshell terminates, so config changes and hotplug restart
    // only the affected output.
    Process {
        id: cleanup
        command: [Quickshell.shellPath("scripts/wallpaper-player"), "cleanup"]
        running: true
        stdout: StdioCollector { onStreamFinished: {
            try { root.awwwAvailable = JSON.parse(text).awww === true } catch (e) {}
        }}
        onExited: root.ready = true
    }
    Process {
        id: daemon
        command: ["awww-daemon", "--namespace", "abyssal", "--format", "argb", "--no-cache"]
        running: root.ready && root.useAwww
        onRunningChanged: if (running) daemonWait.running = true
        onExited: {
            root.daemonReady = false
            if (root.useAwww) root.awwwAvailable = false
        }
    }
    Process {
        id: daemonWait
        command: [Quickshell.shellPath("scripts/wallpaper-player"), "wait-daemon"]
        onExited: code => {
            root.daemonReady = code === 0
            if (code !== 0) root.awwwAvailable = false
        }
    }

    // Keyed by output, so the other outputs' players keep running when one
    // output's entry changes. A changed entry updates its delegate in place
    // (ScriptModel keeps the row), so the player restarts itself on a new key.
    ScriptModel {
        id: players
        values: root.ready && (!root.useAwww || root.daemonReady) ? root.entries : []
        objectProp: "id"
    }
    Instantiator {
        model: players
        delegate: WallpaperComponents.Output {}
    }

}
