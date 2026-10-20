pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Bar layout: which bars each monitor has, on which edge, and what widgets
// sit in their start / center / end sections. Stored in
// ~/.config/abyssal/layout.json and reloaded live; the future settings app
// and the edit mode both write this same file.
//
// {
//   "version": 1,
//   "monitors": {
//     "*":    { "bars": [ ...used by any monitor without its own entry... ] },
//     "DP-4": { "bars": [ ... ] }
//   }
// }
//
// A bar: { "edge": "top|bottom|left|right", "style": "islands|solid",
//          "size": 42, "visibility": "always|hidden",
//          "start": [widget...], "center": [...], "end": [...] }
// A widget is its id ("clock") or { "id": "clock", ...options }.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/abyssal"
    readonly property string path: dir + "/layout.json"

    // Moonlit's islands bar, on top of every monitor.
    readonly property var defaultLayout: ({
        version: 1,
        monitors: {
            "*": {
                bars: [{
                    edge: "top",
                    style: "islands",
                    size: 42,
                    visibility: "always",
                    start: ["logo", "workspaces", "window-title"],
                    center: ["clock"],
                    end: ["ram", "cpu", "temp", "battery", "network", "separator",
                          "recording", "bluetooth", "volume", "separator", "tray", "quick-settings", "power"]
                }]
            }
        }
    })

    property var data: defaultLayout

    readonly property var edges: ["top", "bottom", "left", "right"]

    readonly property var sections: ["start", "center", "end"]
    readonly property int minSize: 28
    readonly property int maxSize: 96

    function isVertical(edge) {
        return edge === "left" || edge === "right"
    }

    function rawBars(output) {
        const monitors = (data && data.monitors) || {}
        const entry = monitors[output] || monitors["*"] || { bars: [] }
        return entry.bars || []
    }

    // Normalised bars for one output, at most one per edge.
    function barsFor(output) {
        const seen = {}
        const out = []
        for (const b of rawBars(output)) {
            const edge = edges.includes(b.edge) ? b.edge : "top"
            if (seen[edge] || b.visibility === "hidden") continue
            seen[edge] = true
            out.push({
                edge: edge,
                style: b.style === "solid" ? "solid" : "islands",
                size: Math.max(minSize, Math.min(maxSize, b.size || (isVertical(edge) ? 46 : 42))),
                visibility: b.visibility === "autohide" ? "autohide" : "always",
                start: normalise(b.start),
                center: normalise(b.center),
                end: normalise(b.end)
            })
        }
        return out
    }

    // Keeps indices aligned with the stored lists, so edits address the
    // same entry the bar shows; unknown ids are skipped when rendering.
    function normalise(list) {
        return (list || []).map(w => typeof w === "string" ? { id: w } : (w && w.id ? w : { id: "" }))
    }

    // ── Editing ─────────────────────────────────────────────────────────
    // Every edit writes the monitor's own entry. The first edit on a
    // monitor copies the shared "*" layout, so the other monitors keep it.
    function edit(output, change) {
        const next = JSON.parse(JSON.stringify(data || { version: 1, monitors: {} }))
        next.monitors = next.monitors || {}
        if (!next.monitors[output])
            next.monitors[output] = JSON.parse(JSON.stringify(next.monitors["*"] || { bars: [] }))
        const bars = next.monitors[output].bars = next.monitors[output].bars || []
        change(bars)
        data = next
        save()
    }

    function findBar(bars, edge) {
        return bars.find(b => b.edge === edge)
    }

    function addBar(output, edge) {
        edit(output, bars => {
            if (findBar(bars, edge)) return
            bars.push({ edge: edge, style: "islands", size: isVertical(edge) ? 46 : 42,
                        visibility: "always", start: [], center: [], end: [] })
        })
    }

    function removeBar(output, edge) {
        edit(output, bars => {
            const i = bars.findIndex(b => b.edge === edge)
            if (i >= 0) bars.splice(i, 1)
        })
    }

    function setBar(output, edge, key, value) {
        edit(output, bars => {
            const b = findBar(bars, edge)
            if (!b) return
            if (key === "size") value = Math.max(minSize, Math.min(maxSize, value))
            b[key] = value
        })
    }

    // Moving a bar to another edge keeps its widgets; refused if taken.
    function moveBar(output, edge, toEdge) {
        edit(output, bars => {
            if (findBar(bars, toEdge)) return
            const b = findBar(bars, edge)
            if (!b) return
            b.edge = toEdge
            if (isVertical(edge) !== isVertical(toEdge)) b.size = isVertical(toEdge) ? 46 : 42
        })
    }

    function addWidget(output, edge, section, id) {
        edit(output, bars => {
            const b = findBar(bars, edge)
            if (!b) return
            b[section] = b[section] || []
            b[section].push(id)
        })
    }

    function removeWidget(output, edge, section, index) {
        edit(output, bars => {
            const b = findBar(bars, edge)
            if (b && b[section]) b[section].splice(index, 1)
        })
    }

    // toIndex counts positions in the target section without the moved
    // widget, which is how a drop position is measured.
    function moveWidget(output, edge, fromSection, fromIndex, toSection, toIndex) {
        edit(output, bars => {
            const b = findBar(bars, edge)
            if (!b || !b[fromSection]) return
            const w = b[fromSection].splice(fromIndex, 1)[0]
            if (w === undefined) return
            b[toSection] = b[toSection] || []
            b[toSection].splice(Math.max(0, Math.min(toIndex, b[toSection].length)), 0, w)
        })
    }

    // Puts this monitor back on the shared layout.
    function resetMonitor(output) {
        const next = JSON.parse(JSON.stringify(data))
        if (next.monitors && next.monitors[output] && output !== "*") delete next.monitors[output]
        data = next
        save()
    }

    function hasOwnLayout(output) {
        return !!(data && data.monitors && data.monitors[output])
    }

    function save() {
        file.setText(JSON.stringify(data, null, 2) + "\n")
    }

    FileView {
        id: file
        path: root.path
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                root.data = JSON.parse(text())
            } catch (e) {
                console.warn("abyssal: layout.json is not valid JSON, keeping the last good layout:", e)
            }
        }
        // First start: write the default so there is a file to edit.
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                Quickshell.execDetached(["mkdir", "-p", root.dir])
                root.data = root.defaultLayout
                saveLater.start()
            }
        }
    }
    Timer { id: saveLater; interval: 300; onTriggered: root.save() }
}
