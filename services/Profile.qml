pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
Singleton {
    id: root
    property var data: ({})
    property bool writable: false
    readonly property string displayName: data.displayName || Quickshell.env("USER") || "User"
    readonly property string avatar: data.avatar || ""
    function setAvatar(path) {
        if (!writable) return
        data = Object.assign({}, data, {avatar: path})
        mkdir.running = true
    }
    Process {
        id: mkdir
        command: ["mkdir", "-p", (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/abyssal"]
        onExited: code => {if (code === 0) file.setText(JSON.stringify(root.data, null, 2) + "\n")}
    }
    FileView {
        id: file
        path: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/abyssal/profile.json"
        blockLoading: true; watchChanges: true; printErrors: false
        onFileChanged: reload()
        onLoaded: { try { const d = JSON.parse(text()); if (!d || typeof d !== "object" || Array.isArray(d)) throw Error("Invalid profile"); root.data = d; root.writable = true } catch (e) {root.writable = false} }
        onLoadFailed: err => root.writable = err === FileViewError.FileNotFound
    }
    Component.onCompleted: file.text()
}
