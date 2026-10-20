pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon. Every notification goes into `history` (for the
// notification centre later) and, unless Do Not Disturb is on, out as a
// toast on the monitor you are working on.
Singleton {
    id: root

    property bool dnd: false
    property int  toastDuration: 4200
    property int  maxToasts: 5
    property var  history: []

    signal toast(var item)

    function push(app, title, body, appIcon) {
        const item = {
            nid: Date.now() + Math.random(),
            app: app || "Abyssal",
            title: title || "",
            body: body || "",
            icon: appIcon || "",
            time: Qt.formatDateTime(new Date(), "hh:mm")
        }
        const next = history.slice()
        next.unshift(item)
        if (next.length > 50) next.length = 50
        history = next
        if (!dnd) toast(item)
    }

    function remove(nid) {
        history = history.filter(n => n.nid !== nid)
    }

    function clear() {
        history = []
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        imageSupported: false
        actionsSupported: false
        onNotification: n => root.push(n.appName, n.summary, n.body, n.appIcon)
    }

    // qs -c abyssal ipc call notify send "App" "Title" "Body"
    IpcHandler {
        target: "notify"
        function send(app: string, title: string, body: string): void {
            root.push(app, title, body, "")
        }
        function dnd(on: bool): void {
            root.dnd = on
        }
    }
}
