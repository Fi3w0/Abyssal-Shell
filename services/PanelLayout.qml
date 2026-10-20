pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Panels: every bar, taskbar and dock is the same object, configured by
// its settings. Stored in ~/.config/abyssal/layout.json, reloaded live; edit
// mode and the future settings app write this same file.
//
// {
//   "version": 2,
//   "monitors": {
//     "*":    { "panels": [ ...used by any monitor without its own entry... ] },
//     "DP-4": { "panels": [ ... ] }
//   }
// }
//
// A panel:
//   edge        top | bottom | left | right
//   width       fill (one strip) | fit (one pill around the content)
//               | islands (one pill per group between spacers) | custom
//   length      custom width, percent of the edge
//   align       start | center | end (fit and custom)
//   look        glass | solid
//   floating    gap from the screen edge, rounded
//   size        thickness in px
//   visibility  always | autohide | below (no reserved space)
//   items       widget ids or { "id": ..., options }, "spacer" splits groups
//
// Version 1 files (bars with start/center/end) are migrated on load.
Singleton {
    id: root

    readonly property string dir: Quickshell.env("HOME") + "/.config/abyssal"
    readonly property string path: dir + "/layout.json"

    readonly property var edges: ["top", "bottom", "left", "right"]
    readonly property int minSize: 24
    readonly property int maxSize: 96

    // True until a layout exists; shell.qml shows the preset picker.
    property bool firstRun: false
    property var data: ({ version: 2, monitors: {} })

    // ── Presets ─────────────────────────────────────────────────────────
    readonly property var topBar: ({
        edge: "top", width: "islands", align: "center", length: 60, look: "glass", floating: true,
        size: 42, visibility: "always",
        items: ["logo", "workspaces", "window-title", "spacer", "clock", "spacer",
                "ram", "cpu", "temp", "battery", "network", "separator",
                "recording", "bluetooth", "volume", "separator", "tray", "quick-settings", "power"]
    })
    readonly property var presets: ({
        "classic": {
            name: "Classic taskbar",
            panels: [{
                edge: "bottom", width: "fill", align: "center", length: 60, look: "solid", floating: false,
                size: 48, visibility: "always",
                items: ["launcher", "separator", { id: "task-manager", style: "titles", pinned: ["kitty", "firefox", "firefox-bin", "org.kde.dolphin"] }, "spacer",
                        "tray", "network", "bluetooth", "volume", "quick-settings", { id: "clock", date: true }]
            }]
        },
        "rice": {
            name: "Top bar + dock",
            panels: [topBar, {
                edge: "bottom", width: "fit", align: "center", length: 60, look: "glass", floating: true,
                size: 58, visibility: "always",
                items: ["launcher", "separator", { id: "task-manager", style: "icons", pinned: ["kitty", "firefox", "firefox-bin", "org.kde.dolphin"] }]
            }]
        },
        "topbar": {
            name: "Top bar only",
            panels: [topBar]
        }
    })

    function applyPreset(output, key) {
        const p = presets[key]
        if (!p) return
        const next = clone(data)
        next.version = 2
        next.monitors = next.monitors || {}
        next.monitors[output] = { panels: clone(p.panels) }
        data = next
        firstRun = false
        save()
    }

    // ── Reading ─────────────────────────────────────────────────────────
    function isVertical(edge) {
        return edge === "left" || edge === "right"
    }

    function rawPanels(output) {
        const monitors = (data && data.monitors) || {}
        const entry = monitors[output] || monitors["*"] || { panels: [] }
        return entry.panels || []
    }

    function hasOwnLayout(output) {
        return !!(data && data.monitors && data.monitors[output])
    }

    // Normalised panels for one output, at most one per edge.
    function panelsFor(output) {
        const seen = {}
        const out = []
        for (const p of rawPanels(output)) {
            const edge = edges.includes(p.edge) ? p.edge : "top"
            if (seen[edge]) continue
            seen[edge] = true
            out.push(normalise(p, edge))
        }
        return out
    }

    function normalise(p, edge) {
        const vertical = isVertical(edge)
        return {
            edge: edge,
            width: ["fill", "fit", "islands", "custom"].includes(p.width) ? p.width : "islands",
            align: ["start", "center", "end"].includes(p.align) ? p.align : "center",
            length: Math.max(10, Math.min(100, p.length || 60)),
            look: p.look === "solid" ? "solid" : "glass",
            floating: p.floating !== false,
            size: Math.max(minSize, Math.min(maxSize, p.size || (vertical ? 46 : 42))),
            visibility: ["always", "autohide", "below"].includes(p.visibility) ? p.visibility : "always",
            // Indices stay aligned with the stored list so edits address
            // the entry the panel shows; unknown ids render as nothing.
            items: (p.items || []).map(w => typeof w === "string" ? { id: w } : (w && w.id ? w : { id: "" }))
        }
    }

    // ── Editing ─────────────────────────────────────────────────────────
    function clone(o) {
        return JSON.parse(JSON.stringify(o))
    }

    // Every edit writes the monitor's own entry. The first edit on a
    // monitor copies the shared "*" layout, so the other monitors keep it.
    function edit(output, change) {
        const next = clone(data)
        next.version = 2
        next.monitors = next.monitors || {}
        if (!next.monitors[output])
            next.monitors[output] = clone(next.monitors["*"] || { panels: [] })
        next.monitors[output].panels = next.monitors[output].panels || []
        change(next.monitors[output].panels, next)
        data = next
        save()
    }

    function find(panels, edge) {
        return panels.find(p => p.edge === edge)
    }

    function freeEdges(output) {
        const used = panelsFor(output).map(p => p.edge)
        return edges.filter(e => !used.includes(e))
    }

    function addPanel(output, edge) {
        edit(output, panels => {
            if (find(panels, edge)) return
            panels.push({ edge: edge, width: "islands", align: "center", length: 60, look: "glass",
                          floating: true, size: isVertical(edge) ? 46 : 42, visibility: "always",
                          items: ["clock"] })
        })
    }

    function removePanel(output, edge) {
        let removed = null
        edit(output, panels => {
            const i = panels.findIndex(p => p.edge === edge)
            if (i >= 0) removed = panels.splice(i, 1)[0]
        })
        return removed
    }

    // Puts a removed panel back (the undo toast).
    function restorePanel(output, panel) {
        edit(output, panels => {
            if (!find(panels, panel.edge)) panels.push(panel)
        })
    }

    function setPanel(output, edge, key, value) {
        edit(output, panels => {
            const p = find(panels, edge)
            if (!p) return
            if (key === "size") value = Math.max(minSize, Math.min(maxSize, value))
            if (key === "length") value = Math.max(10, Math.min(100, value))
            p[key] = value
        })
    }

    // Moves a panel to another edge, on this or another monitor. Refused
    // when that edge already has a panel.
    function movePanel(output, edge, toOutput, toEdge) {
        if (output === toOutput && edge === toEdge) return
        if (panelsFor(toOutput).find(p => p.edge === toEdge)) return
        let moving = null
        edit(output, panels => {
            const i = panels.findIndex(p => p.edge === edge)
            if (i >= 0) moving = panels.splice(i, 1)[0]
        })
        if (!moving) return
        if (isVertical(edge) !== isVertical(toEdge)) moving.size = isVertical(toEdge) ? 46 : 42
        moving.edge = toEdge
        edit(toOutput, panels => panels.push(moving))
    }

    // Same panel on another monitor, at the same edge or the first free one.
    function clonePanel(output, edge, toOutput) {
        const src = rawPanels(output).find(p => p.edge === edge)
        if (!src) return
        const free = freeEdges(toOutput)
        if (free.length === 0) return
        const copy = clone(src)
        copy.edge = free.includes(edge) ? edge : free[0]
        edit(toOutput, panels => panels.push(copy))
    }

    function addItem(output, edge, item) {
        edit(output, panels => {
            const p = find(panels, edge)
            if (!p) return
            p.items = p.items || []
            p.items.push(item)
        })
    }

    function removeItem(output, edge, index) {
        edit(output, panels => {
            const p = find(panels, edge)
            if (p && p.items) p.items.splice(index, 1)
        })
    }

    // toIndex is measured without the moved item, as a drop position is.
    function moveItem(output, edge, from, to) {
        edit(output, panels => {
            const p = find(panels, edge)
            if (!p || !p.items) return
            const item = p.items.splice(from, 1)[0]
            if (item === undefined) return
            p.items.splice(Math.max(0, Math.min(to, p.items.length)), 0, item)
        })
    }

    // Sets one option on one widget ({ id: "clock", date: true }).
    function setItemOption(output, edge, index, key, value) {
        edit(output, panels => {
            const p = find(panels, edge)
            if (!p || !p.items || index >= p.items.length) return
            let item = p.items[index]
            if (typeof item === "string") item = { id: item }
            item[key] = value
            p.items[index] = item
        })
    }

    // Puts this monitor back on the shared layout.
    function resetMonitor(output) {
        const next = clone(data)
        if (next.monitors && next.monitors[output] && output !== "*") delete next.monitors[output]
        data = next
        save()
    }

    // ── Version 1 (bars) → version 2 (panels) ───────────────────────────
    function migrate(d) {
        if (!d || d.version === 2) return d
        const out = { version: 2, monitors: {} }
        for (const key in (d.monitors || {})) {
            out.monitors[key] = {
                panels: ((d.monitors[key] || {}).bars || []).map(b => ({
                    edge: b.edge,
                    width: b.style === "solid" ? "fill" : "islands",
                    align: "center",
                    length: 60,
                    look: "glass",
                    floating: b.style !== "solid",
                    size: b.size,
                    visibility: b.visibility === "autohide" ? "autohide" : "always",
                    items: [].concat(b.start || [], b.center && b.center.length ? ["spacer"].concat(b.center) : [],
                                     ["spacer"], b.end || [])
                }))
            }
        }
        return out
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
                const parsed = JSON.parse(text())
                const migrated = root.migrate(parsed)
                root.data = migrated
                root.firstRun = false
                if (parsed.version !== 2) root.save()
            } catch (e) {
                console.warn("abyssal: layout.json is not valid JSON, keeping the last good layout:", e)
            }
        }
        // No layout yet: the shell shows the preset picker; until one is
        // picked, every monitor gets the top bar.
        onLoadFailed: err => {
            if (err === FileViewError.FileNotFound) {
                Quickshell.execDetached(["mkdir", "-p", root.dir])
                root.data = { version: 2, monitors: { "*": { panels: [root.topBar] } } }
                root.firstRun = true
            }
        }
    }
}
