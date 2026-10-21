pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Removable drives (USB sticks, SD cards, external disks) through udisks2:
// lsblk for the list, udisks2's D-Bus signals (gdbus monitor) to notice
// changes, udisksctl to mount, unmount and power off (as the user, through
// polkit, like Dolphin). Nothing is mounted on its own; plugging a drive in
// shows a toast that opens the drives panel.
Singleton {
    id: root

    // [{ id, path, name, model, size, removable partitions: [{ path, label,
    //    fstype, size, mounts: [..], used, avail }] }]
    property var drives: []
    readonly property int count: drives.length
    property string error: ""
    // Path of the partition/drive an action is running on.
    property string working: ""

    function refresh() {
        if (!lister.running) lister.running = true
    }

    Process {
        id: lister
        command: ["lsblk", "-J", "-b", "-o", "NAME,PATH,LABEL,SIZE,FSTYPE,MOUNTPOINTS,HOTPLUG,RM,TRAN,TYPE,MODEL,VENDOR,FSUSED,FSAVAIL"]
        stdout: StdioCollector {
            onStreamFinished: {
                let d
                try { d = JSON.parse(text).blockdevices || [] } catch (e) { return }
                const out = []
                for (const disk of d) {
                    if (disk.type !== "disk") continue
                    if (!(disk.hotplug || disk.rm || disk.tran === "usb" || disk.tran === "mmc")) continue
                    if (/^(zram|loop|sr)/.test(disk.name)) continue
                    // A disk without partitions can hold a filesystem itself.
                    const parts = (disk.children || []).concat(disk.fstype ? [disk] : [])
                    .filter(p => p.fstype && p.fstype !== "swap")
                    .map(p => ({
                        path: p.path, label: p.label || "", fstype: p.fstype, size: Number(p.size) || 0,
                        mounts: (p.mountpoints || []).filter(m => m),
                        used: Number(p.fsused) || 0, avail: Number(p.fsavail) || 0
                    }))
                    const model = ((disk.vendor || "").trim() + " " + (disk.model || "").trim()).trim()
                    out.push({
                        id: disk.path, path: disk.path, size: Number(disk.size) || 0, model: model,
                        name: parts.find(p => p.label) ? parts.find(p => p.label).label : model || disk.name,
                        partitions: parts
                    })
                }
                root.announce(out)
                root.drives = out
            }
        }
    }

    // A drive that was not here before: toast (not on the first look).
    property bool _seeded: false
    function announce(next) {
        if (_seeded) {
            for (const dr of next) {
                if (drives.some(o => o.id === dr.id)) continue
                Notifications.push("Drives", dr.name + " connected",
                    size(dr.size) + (dr.partitions.length ? " · " + dr.partitions.map(p => p.fstype).join(", ") : " · no filesystem"),
                    "", null, false, () => root.openPanel())
            }
        }
        _seeded = true
    }
    function openPanel() {
        const out = Shell.targetOutput()
        const panel = PanelLayout.panelsFor(out)[0]
        const screen = Quickshell.screens.find(s => s.name === out)
        if (!panel || !screen) return
        const vertical = panel.edge === "left" || panel.edge === "right"
        Shell.detail = null
        Shell.toggleDetail(out, panel.edge, "drives", (vertical ? screen.height : screen.width) / 2, panel.size)
    }

    function size(bytes) {
        const u = ["B", "KB", "MB", "GB", "TB"]
        let i = 0, v = bytes
        while (v >= 1000 && i < u.length - 1) { v /= 1000; i++ }
        return (v >= 100 || i === 0 ? Math.round(v) : v.toFixed(1)) + " " + u[i]
    }

    // ── Actions ─────────────────────────────────────────────────────────
    // Mounts if needed, then opens it in the file manager.
    function open(part) {
        if (part.mounts.length) { Quickshell.execDetached(["xdg-open", part.mounts[0]]); return }
        run(part.path, ["sh", "-c", "out=$(udisksctl mount --no-user-interaction -b \"$1\") || exit 1; "
            + "dir=$(printf '%s' \"$out\" | sed -n 's/^Mounted .* at //p'); [ -n \"$dir\" ] && exec xdg-open \"$dir\"", "sh", part.path])
    }
    function unmount(part) {
        run(part.path, ["udisksctl", "unmount", "--no-user-interaction", "-b", part.path])
    }
    // Unmounts every mounted partition, then powers the drive off.
    function eject(drive) {
        const cmds = drive.partitions.filter(p => p.mounts.length)
            .map(p => "udisksctl unmount --no-user-interaction -b '" + p.path.replace(/'/g, "") + "'")
        cmds.push("udisksctl power-off --no-user-interaction -b '" + drive.path.replace(/'/g, "") + "'")
        run(drive.path, ["sh", "-c", "set -e; " + cmds.join("; ")])
    }
    function run(path, cmd) {
        if (actor.running) return
        error = ""
        working = path
        actor.command = cmd
        actor.running = true
    }
    Process {
        id: actor
        stderr: StdioCollector {
            onStreamFinished: {
                const t = text.trim()
                // udisksctl: "Error ...: GDBus.Error:org.freedesktop.UDisks2.Error.DeviceBusy: ... target is busy"
                if (t) root.error = /busy/i.test(t) ? "Still in use: close the files or apps using it first"
                    : t.replace(/^[\s\S]*GDBus\.Error:[^:]+:\s*/, "").split("\n")[0]
            }
        }
        onExited: { root.working = ""; root.refresh() }
    }

    // ── Watching for changes ────────────────────────────────────────────
    // udisks2 starts on demand; `udisksctl status` wakes it so its signals flow.
    Process {
        running: true
        command: ["udisksctl", "status"]
        onExited: monitor.running = true
    }
    Process {
        id: monitor
        command: ["gdbus", "monitor", "--system", "--dest", "org.freedesktop.UDisks2"]
        stdout: SplitParser { onRead: settle.restart() }
        onExited: restart.start()
    }
    Timer { id: restart; interval: 5000; onTriggered: monitor.running = true }
    Timer { id: settle; interval: 400; onTriggered: root.refresh() }

    Component.onCompleted: refresh()
}
