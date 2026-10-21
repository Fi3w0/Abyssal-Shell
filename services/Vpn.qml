pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// VPN and WireGuard connections from the system's NetworkManager (nmcli),
// kept current through `nmcli monitor`. The quick-menu tile toggles the
// last one used; the Wi-Fi page lists them all. A VPN that needs a password
// typed in each time can't connect from here (no secrets agent in TideWM):
// the error says so.
Singleton {
    id: root

    // [{ name, uuid, type: "vpn" | "wireguard", active, state }]
    property var connections: []
    readonly property bool available: have && connections.length > 0
    readonly property var active: connections.filter(c => c.active)
    readonly property bool on: active.length > 0
    property bool have: false
    property string working: ""     // uuid being switched
    property string error: ""

    // The one the tile toggles: the active one, else the last used.
    property string lastUuid: ""
    readonly property var preferred: active[0] || connections.find(c => c.uuid === lastUuid) || connections[0] || null

    // nmcli -t -e yes: ":"-separated, with ":" and "\\" escaped by "\\".
    function fields(line) {
        const out = []
        let cur = ""
        for (let i = 0; i < line.length; i++) {
            const ch = line[i]
            if (ch === "\\" && i + 1 < line.length) { cur += line[++i]; continue }
            if (ch === ":") { out.push(cur); cur = ""; continue }
            cur += ch
        }
        out.push(cur)
        return out
    }

    function refresh() {
        if (!lister.running) lister.running = true
    }
    function toggle(c) {
        if (!c || setter.running) return
        error = ""
        working = c.uuid
        if (!c.active) {
            lastUuid = c.uuid
            lastFile.setText(c.uuid)
        }
        setter.command = ["nmcli", "--wait", "30", "connection", c.active ? "down" : "up", "uuid", c.uuid]
        setter.running = true
    }
    function toggleDefault() { toggle(preferred) }

    Process {
        id: lister
        command: ["nmcli", "-t", "-e", "yes", "-f", "NAME,UUID,TYPE,ACTIVE,STATE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.have = true
                const out = []
                for (const line of text.split("\n")) {
                    const f = root.fields(line)
                    if (f.length < 4) continue
                    const type = f[2] === "vpn" ? "vpn" : f[2] === "wireguard" ? "wireguard" : ""
                    if (!type) continue
                    out.push({ name: f[0], uuid: f[1], type: type, active: f[3] === "yes", state: f[4] || "" })
                }
                root.connections = out
            }
        }
        onExited: code => { if (code === 127) root.have = false }
    }
    Process {
        id: setter
        stderr: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                if (!t) return
                root.error = /secrets were required|no secrets|password/i.test(t)
                    ? "Needs a password: save it in the connection's settings first"
                    : t.replace(/^Error:\s*/, "").split("\n")[0]
            }
        }
        onExited: { root.working = ""; root.refresh() }
    }

    FileView {
        id: lastFile
        path: Quickshell.statePath("vpn-last")
        printErrors: false
        onLoaded: root.lastUuid = text().trim()
    }

    // NetworkManager tells about every change; refresh once things settle.
    Process {
        id: monitor
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: settle.restart() }
        onExited: code => { if (code !== 127) restart.start() }
    }
    Timer { id: restart; interval: 5000; onTriggered: monitor.running = true }
    Timer { id: settle; interval: 300; onTriggered: root.refresh() }

    Component.onCompleted: refresh()
}
