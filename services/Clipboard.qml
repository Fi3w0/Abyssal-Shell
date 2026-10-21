pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Clipboard history. `wl-paste --watch` (TideWM has wlr-data-control)
// runs scripts/clip-store on every copy; it saves text or images into
// Abyssal's state folder and reports each one here. A copy that is already
// in the history moves to the top. The newest 100 are kept; pinned entries
// are never dropped. Password-manager copies are never stored.
Singleton {
    id: root

    readonly property string dir: Quickshell.statePath("clipboard")
    readonly property int limit: 100
    // [{ kind: "text"|"image", file, preview, hash, ts, pinned }], newest first
    property var entries: []
    property bool loaded: false

    function add(e) {
        const old = entries.find(x => x.hash === e.hash)
        if (old && old.file !== e.file) removeFile(e.file)
        const item = old ? Object.assign({}, old, { ts: e.ts }) : Object.assign({ pinned: false }, e)
        let next = entries.filter(x => x.hash !== e.hash)
        next.unshift(item)
        const unpinned = next.filter(x => !x.pinned)
        if (unpinned.length > limit) {
            const drop = unpinned.slice(limit)
            for (const d of drop) removeFile(d.file)
            next = next.filter(x => !drop.includes(x))
        }
        entries = next
        save()
    }

    // Puts an entry back on the clipboard (the watcher then moves it up).
    function copy(e) {
        copier.command = ["sh", "-c", 'wl-copy --type "$2" < "$1"', "sh", e.file,
                          e.kind === "image" ? (e.file.endsWith(".png") ? "image/png" : e.file.endsWith(".webp") ? "image/webp" : "image/jpeg")
                                             : "text/plain;charset=utf-8"]
        copier.running = true
    }

    function togglePin(e) {
        entries = entries.map(x => x.hash === e.hash ? Object.assign({}, x, { pinned: !x.pinned }) : x)
        save()
    }

    function remove(e) {
        removeFile(e.file)
        entries = entries.filter(x => x.hash !== e.hash)
        save()
    }

    // Everything except pinned entries.
    function clear() {
        for (const e of entries) if (!e.pinned) removeFile(e.file)
        entries = entries.filter(e => e.pinned)
        save()
    }

    function removeFile(path) {
        if (path && path.startsWith(dir + "/")) Quickshell.execDetached(["rm", "-f", path])
    }

    function save() {
        if (loaded) index.setText(JSON.stringify(entries) + "\n")
    }

    Process { id: copier }

    Process {
        id: watcher
        command: ["wl-paste", "--watch", Quickshell.shellPath("scripts/clip-store"), root.dir]
        running: root.loaded
        stdout: SplitParser {
            onRead: line => {
                try { root.add(JSON.parse(line)) } catch (e) {}
            }
        }
        // The compositor restarted or wl-paste died: watch again.
        onExited: restart.start()
    }
    Timer { id: restart; interval: 3000; onTriggered: watcher.running = root.loaded }

    // Reads the saved history (none on first run), then starts watching.
    Process {
        id: loader
        running: true
        command: ["sh", "-c", 'mkdir -p "$1" && cat "$1/index.json" 2>/dev/null || true', "sh", root.dir]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = text.trim() ? JSON.parse(text) : []
                    if (Array.isArray(parsed)) root.entries = parsed.filter(e => e && e.file && e.hash)
                } catch (e) {
                    console.warn("abyssal: clipboard index is not valid JSON, starting empty:", e)
                }
                root.loaded = true
            }
        }
    }

    FileView {
        id: index
        path: root.dir + "/index.json"
        preload: false
        printErrors: false
    }

    // qs -c abyssal ipc call clipboard clear
    IpcHandler {
        target: "clipboard"
        function clear(): void { root.clear() }
    }
}
