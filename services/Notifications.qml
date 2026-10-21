pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon. Every notification goes into `history` (the
// notification centre) and, unless Do Not Disturb is on, out as a toast on
// the monitor you are working on. Real notifications stay tracked, so the
// centre can run their actions and dismissing one also closes it for the
// sending app; one the app withdraws leaves the history.
Singleton {
    id: root

    property bool dnd: false
    property int  toastDuration: 4200
    property int  maxToasts: 5
    property var  history: []
    // Arrived since the centre was last opened.
    property int  unread: 0

    signal toast(var item)

    // `quiet`: into the history only, no toast and no unread dot (the ones
    // the server hands back after a shell reload, like Plasma does).
    function push(app, title, body, appIcon, notification, quiet) {
        const n = notification || null
        const item = {
            nid: Date.now() + Math.random(),
            app: app || "Abyssal",
            title: title || "",
            body: body || "",
            icon: appIcon || "",
            ts: Date.now(),
            time: Qt.formatDateTime(new Date(), "hh:mm"),
            notification: n,
            hasDefault: n ? n.actions.some(a => a.identifier === "default") : false,
            actions: n ? n.actions.filter(a => a.identifier !== "default").map(a => ({ id: a.identifier, text: a.text })) : []
        }
        const next = history.slice()
        next.unshift(item)
        while (next.length > 50) drop(next.pop().nid, true)
        history = next
        if (n) n.closed.connect(() => root.drop(item.nid, false))
        if (quiet) return
        unread++
        if (!dnd) toast(item)
    }

    // Runs an action ("default" = the notification itself was clicked),
    // then removes it.
    function invoke(nid, id) {
        const item = history.find(i => i.nid === nid)
        if (item && item.notification) {
            const action = item.notification.actions.find(a => a.identifier === id)
            if (action) action.invoke()
        }
        remove(nid)
    }

    // Removes from the history and tells the app it was dismissed.
    function remove(nid) {
        drop(nid, true)
    }

    function clear() {
        for (const item of history.slice()) drop(item.nid, true)
    }

    function markRead() {
        unread = 0
    }

    function drop(nid, dismiss) {
        const item = history.find(i => i.nid === nid)
        if (!item) return
        const n = item.notification
        item.notification = null
        history = history.filter(i => i.nid !== nid)
        if (dismiss && n) n.dismiss()
    }

    NotificationServer {
        keepOnReload: true
        bodySupported: true
        imageSupported: false
        actionsSupported: true
        onNotification: n => {
            n.tracked = true
            root.push(n.appName, n.summary, n.body, n.appIcon, n, n.lastGeneration)
        }
    }

    // qs -c abyssal ipc call notify send "App" "Title" "Body"
    IpcHandler {
        target: "notify"
        function send(app: string, title: string, body: string): void {
            root.push(app, title, body, "", null)
        }
        function dnd(on: bool): void {
            root.dnd = on
        }
    }
}
