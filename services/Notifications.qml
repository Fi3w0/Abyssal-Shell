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
    // `onClick`: for the shell's own notifications, run when it is clicked.
    function push(app, title, body, appIcon, notification, quiet, onClick) {
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
            onClick: onClick || null,
            // A picture the app attached (screenshot, cover art), and the
            // server's id for the notification (survives a shell reload).
            image: n && n.image ? String(n.image) : "",
            id: n ? n.id : 0,
            hasDefault: n ? n.actions.some(a => a.identifier === "default") : typeof onClick === "function",
            actions: n ? n.actions.filter(a => a.identifier !== "default").map(a => ({ id: a.identifier, text: a.text })) : []
        }
        // Back after a shell reload: take the place of the copy restored
        // from disk instead of showing it twice.
        const next = history.filter(i => !(i.restored && n && i.id === n.id && i.title === item.title))
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
        if (item && id === "default" && item.onClick) item.onClick()
        else if (item && item.notification) {
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
        imageSupported: true
        actionsSupported: true
        onNotification: n => {
            n.tracked = true
            root.push(n.appName, n.summary, n.body, n.appIcon, n, n.lastGeneration)
        }
    }

    // ── Kept across restarts ────────────────────────────────────────────
    // The history is saved (text, app, icon, file images; not the live
    // notification, so restored ones have no buttons) and comes back marked
    // read. Notifications older than a week are not kept.
    onHistoryChanged: saveTimer.restart()
    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: {
            const keep = root.history.filter(i => Date.now() - i.ts < 7 * 86400000).slice(0, 50).map(i => ({
                id: i.id, app: i.app, title: i.title, body: i.body, icon: i.icon, ts: i.ts, time: i.time,
                image: /^(\/|file:)/.test(i.image) ? i.image : ""
            }))
            saved.setText(JSON.stringify(keep))
        }
    }
    FileView {
        id: saved
        path: Quickshell.statePath("notifications.json")
        printErrors: false
        blockLoading: true
    }
    Component.onCompleted: {
        let list = []
        try { list = JSON.parse(saved.text() || "[]") } catch (e) {}
        if (!Array.isArray(list)) return
        const restored = list.filter(i => i && Date.now() - i.ts < 7 * 86400000).map(i => Object.assign({
            nid: i.ts + Math.random(), notification: null, onClick: null, hasDefault: false, actions: [], restored: true
        }, i))
        // Live ones the server handed back already sit in front.
        root.history = root.history.concat(restored.filter(r => !root.history.some(h => h.id === r.id && r.id && h.title === r.title)))
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
