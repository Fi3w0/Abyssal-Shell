pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// TideWM state, read through tidectl. `tidectl subscribe` streams one JSON
// line per compositor event; each burst of events triggers one re-query of
// workspaces and windows, so the bars always show TideWM's own truth.
Singleton {
    id: root

    // [{ output, workspace, active, window_count }]
    property var workspaces: []
    // [{ window_id, app_id, title, output, workspace, focused, urgent, ... }]
    property var windows: []
    property var focusedWindow: null
    // window_ids, most recently focused first; picks each monitor's title
    property var focusOrder: []
    // { current_idx, names, codes } from `tidectl keyboard-layouts`; null
    // until a compositor with the query answers (older TideWM, or none).
    property var keyboardLayout: null

    readonly property string focusedOutput: focusedWindow ? focusedWindow.output : ""

    function activeWorkspace(output) {
        for (const w of workspaces)
            if (w.output === output && w.active) return w.workspace
        return 1
    }

    // Workspaces 1..max(5, highest known) for one output, Moonlit-style.
    function workspacesFor(output, minimum) {
        const known = {}
        let highest = minimum || 5
        for (const w of workspaces) {
            if (w.output !== output) continue
            known[w.workspace] = w
            highest = Math.max(highest, w.workspace)
        }
        const out = []
        for (let n = 1; n <= highest; n++) {
            const w = known[n]
            out.push({ n: n, active: w ? w.active : false, occupied: w ? w.window_count > 0 : false })
        }
        return out
    }

    // The window a bar on `output` should name: the focused one if it is
    // there, else the most recently focused window on that output's
    // visible workspace.
    function windowFor(output) {
        if (focusedWindow && focusedWindow.output === output) return focusedWindow
        const ws = activeWorkspace(output)
        let best = null
        let bestRank = Infinity
        for (const w of windows) {
            if (w.output !== output || w.workspace !== ws) continue
            const rank = focusOrder.indexOf(w.window_id)
            const r = rank < 0 ? Infinity - 1 : rank
            if (best === null || r < bestRank) { best = w; bestRank = r }
        }
        return best
    }

    // Runs any tidectl action ("close-window", "workspace 3", ...).
    function action(args) {
        Quickshell.execDetached(["tidectl"].concat(args))
    }

    // `workspace-on` switches that monitor even when the focused window is
    // on the other one. An older TideWM rejects it; then fall back to the
    // plain switch, which acts on the focused window's monitor.
    function switchWorkspace(output, n) {
        wsSwitch.fallback = String(n)
        wsSwitch.command = ["tidectl", "workspace-on", output, String(n)]
        wsSwitch.running = true
    }

    Process {
        id: wsSwitch
        property string fallback: ""
        onExited: code => { if (code !== 0) root.action(["workspace", fallback]) }
    }

    function cycleLayout(forward) {
        action([forward ? "switch-layout:next" : "switch-layout:prev"])
    }
    function setLayout(code) {
        action(["switch-layout:" + code])
    }

    function remember(id) {
        if (id === undefined || id === null) return
        const next = focusOrder.filter(x => x !== id)
        next.unshift(id)
        if (next.length > 64) next.length = 64
        focusOrder = next
    }

    // ── Event stream ────────────────────────────────────────────────────
    Process {
        id: subscriber
        command: ["tidectl", "subscribe"]
        running: true
        stdout: SplitParser {
            onRead: line => {
                try {
                    const ev = JSON.parse(line)
                    if (ev.event === "focus-changed" && ev.data) root.remember(ev.data.window_id)
                    if (ev.event === "layout-changed" && ev.data) {
                        const prev = root.keyboardLayout
                        root.keyboardLayout = ev.data
                        // A real switch, not the first answer after (re)connecting.
                        if (prev && prev.current_idx !== ev.data.current_idx) Shell.showOsd("layout", 0, false)
                    }
                } catch (e) {}
                refreshDebounce.restart()
            }
        }
        // TideWM restarted or the socket went away: retry quietly.
        onExited: retry.start()
    }
    Timer { id: retry; interval: 2000; onTriggered: { subscriber.running = true; root.refresh(); layoutQuery.running = true } }

    Timer { id: refreshDebounce; interval: 40; onTriggered: root.refresh() }

    function refresh() {
        wsQuery.running = true
        winQuery.running = true
    }

    Process {
        id: wsQuery
        command: ["tidectl", "--json", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    if (r.ok) root.workspaces = r.data
                } catch (e) {}
            }
        }
    }

    Process {
        id: winQuery
        command: ["tidectl", "--json", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    if (!r.ok) return
                    root.windows = r.data
                    const f = r.data.find(w => w.focused) ?? null
                    root.focusedWindow = f
                    if (f) root.remember(f.window_id)
                } catch (e) {}
            }
        }
    }

    // Queried on start and after a reconnect only; changes arrive as
    // `layout-changed` events, so no polling.
    Process {
        id: layoutQuery
        command: ["tidectl", "--json", "keyboard-layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text)
                    root.keyboardLayout = r.ok ? r.data : null
                } catch (e) {
                    root.keyboardLayout = null
                }
            }
        }
    }

    Component.onCompleted: { refresh(); layoutQuery.running = true }
}
