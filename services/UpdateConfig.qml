pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// One update policy for every widget, tile and popup. Python merges it
// atomically with the existing important/ignore/sudo settings.
Singleton {
    id: root
    readonly property string path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/abyssal/updates.json"
    property var data: ({})
    property bool loaded: false
    property bool writable: false
    property string error: ""
    property var pending: ({})
    property var detected: ({ managers: [], flatpak: false, dnfRepos: [] })
    readonly property int intervalMinutes: typeof data.intervalMinutes === "number"
        ? Math.max(0, Math.min(10080, Math.round(data.intervalMinutes))) : 60
    readonly property bool automatic: intervalMinutes > 0
    readonly property string manager: data.manager || "auto"
    readonly property bool flatpak: data.flatpak !== false
    readonly property bool includeAur: data.includeAur !== false
    readonly property string aurHelper: data.aurHelper || "auto"
    readonly property string dnfRepoMode: data.dnfRepoMode || "all"
    readonly property var dnfRepos: data.dnfRepos || []
    readonly property bool onStartup: data.onStartup !== false
    readonly property bool afterTransactions: data.afterTransactions !== false
    readonly property var sourcePolicy: ({ manager: manager, flatpak: flatpak, includeAur: includeAur,
        aurHelper: aurHelper, dnfRepoMode: dnfRepoMode, dnfRepos: dnfRepos })
    readonly property bool arch: ["pacman", "paru", "yay"].includes(manager)
        || manager === "auto" && (detected.managers || []).includes("pacman")
    readonly property bool fedora: ["dnf", "dnf4", "dnf5"].includes(manager)
        || manager === "auto" && (detected.managers || []).some(m => m.startsWith("dnf"))
    readonly property var names: ({ auto: "Automatic", none: "No system packages", portage: "Portage",
        pacman: "pacman", paru: "paru + pacman", yay: "yay + pacman", dnf: "DNF (automatic)",
        dnf5: "DNF5", dnf4: "DNF4", apt: "APT", xbps: "XBPS" })
    readonly property var managerChoices: {
        const ids = ["auto"].concat(detected.managers || [], ["none"])
        if (!ids.includes(manager)) ids.push(manager)
        return ids.map(id => ({ value: id, label: (names[id] || id)
            + (!['auto', 'none'].includes(id) && !(detected.managers || []).includes(id) ? " (unavailable)" : "") }))
    }
    signal optionsChanged()

    function set(key, value) {
        if (!writable) return
        data = Object.assign({}, data, { [key]: value })
        pending = Object.assign({}, pending, { [key]: value })
        optionsChanged()
        saveDelay.restart()
    }
    function flush() {
        if (writer.running || !Object.keys(pending).length) return
        const changes = pending
        pending = ({})
        writer.command = [Quickshell.shellPath("scripts/updates"), "configure", JSON.stringify(changes)]
        writer.running = true
    }
    function refreshCapabilities() { if (!probe.running) probe.running = true }
    Timer { id: saveDelay; interval: 200; onTriggered: root.flush() }
    Process {
        id: writer
        stdout: StdioCollector { onStreamFinished: {
            try { root.data = Object.assign({}, JSON.parse(text), root.pending); root.error = "" }
            catch (e) {}
        }}
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.error = text.trim().split("\n").slice(-1)[0] }
        onExited: code => {
            if (code !== 0) { root.error = root.error || "Could not save update settings"; file.reload() }
            if (Object.keys(root.pending).length) saveDelay.restart()
        }
    }
    Process {
        id: probe
        command: [Quickshell.shellPath("scripts/updates"), "capabilities"]
        stdout: StdioCollector { onStreamFinished: {
            try { root.detected = JSON.parse(text) } catch (e) {}
        }}
    }
    FileView {
        id: file
        path: root.path
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const parsed = JSON.parse(text())
                if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) throw Error("Expected a JSON object")
                const changed = JSON.stringify(root.data) !== JSON.stringify(parsed)
                root.data = Object.assign({}, parsed, root.pending)
                root.writable = true
                root.error = ""
                if (root.loaded && changed) root.optionsChanged()
            } catch (e) { root.writable = false; root.error = "Invalid updates.json; file left unchanged" }
            root.loaded = true
        }
        onLoadFailed: err => {
            root.writable = err === FileViewError.FileNotFound
            root.loaded = true
            if (root.writable) root.data = ({})
            else root.error = "Could not read update settings"
        }
    }
    Component.onCompleted: file.text()
}
