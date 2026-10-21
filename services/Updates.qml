pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Pending package updates from scripts/updates (Portage, pacman + AUR,
// DNF, APT, XBPS, Flatpak: whichever this system has). Checks a minute
// and a half after start, then every hour, skipping while the system is
// busy (a game, a package manager, high load); again a minute after a
// package manager's log stops changing, and when an upgrade terminal
// closes. The last result is kept, so a restart shows it at once. A toast
// tells about each new batch once.
Singleton {
    id: root

    property var result: ({ sources: [], updates: [], news: 0 })
    property bool checking: false
    property string busy: ""
    readonly property var updates: result.updates || []
    readonly property var sources: result.sources || []
    readonly property int count: updates.length
    readonly property int important: updates.filter(u => u.important).length
    readonly property int news: result.news || 0
    readonly property bool canSync: sources.some(s => s.canSync)
    readonly property string errors: sources.filter(s => s.error).map(s => s.name + ": " + s.error).join("\n")
    readonly property real synced: Math.max(0, ...sources.map(s => s.synced || 0))

    function check(scheduled) {
        if (checker.running) return
        checker.command = [Quickshell.shellPath("scripts/updates"), "check"].concat(scheduled ? ["--scheduled"] : [])
        checking = true
        checker.running = true
    }

    // Upgrades (all sources, or the given ids) / syncs in a terminal.
    function upgrade(ids) {
        if (term.running) return
        term.command = [Quickshell.shellPath("scripts/terminal"), Quickshell.shellPath("scripts/updates"), "upgrade"].concat(ids || [])
        term.running = true
    }
    function sync() {
        if (term.running) return
        term.command = [Quickshell.shellPath("scripts/terminal"), Quickshell.shellPath("scripts/updates"), "sync"]
        term.running = true
    }
    readonly property bool upgrading: term.running

    Process {
        id: checker
        stdout: StdioCollector {
            onStreamFinished: {
                root.checking = false
                let r
                try { r = JSON.parse(text) } catch (e) { return }
                if (r.busy) {
                    root.busy = r.busy
                    retry.restart()
                    return
                }
                root.busy = ""
                root.result = r
                cache.setText(JSON.stringify(r))
                root.announce()
            }
        }
        onExited: checking = false
    }
    Process {
        id: term
        onExited: root.check(false)
    }

    // ── Kept across restarts ────────────────────────────────────────────
    FileView {
        id: cache
        path: Quickshell.statePath("updates.json")
        printErrors: false
        onLoaded: { try { root.result = JSON.parse(text()) } catch (e) {} }
    }
    // What the last toast was about: "source name version" per update.
    property var told: []
    FileView {
        id: toldFile
        path: Quickshell.statePath("updates-told.json")
        printErrors: false
        onLoaded: { try { root.told = JSON.parse(text()) } catch (e) {} }
    }
    function announce() {
        const keys = updates.map(u => u.source + " " + u.name + " " + u.new)
        const fresh = keys.filter(k => !told.includes(k))
        told = keys
        toldFile.setText(JSON.stringify(keys))
        if (!fresh.length) return
        const imp = updates.filter(u => u.important).map(u => u.name.replace(/^.*\//, ""))
        Notifications.push("Updates", count + (count === 1 ? " update available" : " updates available"),
            imp.length ? "Including " + imp.slice(0, 3).join(", ") + (imp.length > 3 ? "…" : "") : "", "", null)
    }

    // ── When to check ───────────────────────────────────────────────────
    Timer { running: true; interval: 90 * 1000; onTriggered: root.check(true) }
    Timer { running: true; repeat: true; interval: 60 * 60 * 1000; onTriggered: root.check(true) }
    Timer { id: retry; interval: 10 * 60 * 1000; onTriggered: root.check(true) }

    // A package manager wrote its log: check once it has been quiet a minute.
    Timer { id: afterLog; interval: 60 * 1000; onTriggered: root.check(false) }
    Instantiator {
        model: ["/var/log/emerge.log", "/var/log/pacman.log", "/var/log/dpkg.log", "/var/log/dnf.rpm.log", "/var/log/dnf5.log"]
        delegate: FileView {
            required property string modelData
            path: modelData
            preload: false
            watchChanges: true
            printErrors: false
            onFileChanged: afterLog.restart()
        }
    }

    // qs -c abyssal ipc call updates check | upgrade | sync | pending
    IpcHandler {
        target: "updates"
        function check(): void { root.check(false) }
        function upgrade(): void { root.upgrade([]) }
        function sync(): void { root.sync() }
        function pending(): int { return root.count }
    }
}
