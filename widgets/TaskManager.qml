import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../services"

// Open and pinned apps (wlr-foreign-toplevel, which TideWM provides).
//   style "icons":  one icon per app, dots for its windows (a dock)
//   style "titles": one button per window with its title (a taskbar)
// Click focuses (cycles an app's windows), a pinned app without windows
// launches; middle click opens a new window; right click: pin, new, close.
Item {
    id: root

    property var ctx
    readonly property bool vertical: ctx ? ctx.vertical : false
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property bool titles: opts.style === "titles" && !vertical
    readonly property bool thisMonitor: opts.scope === "monitor"
    readonly property var pinned: opts.pinned || []
    readonly property int iconSize: Math.round(Math.max(16, Math.min(48, (ctx ? ctx.thickness : 42) * (titles ? 0.46 : 0.6))))

    readonly property var windows: ToplevelManager.toplevels.values.filter(t =>
        !thisMonitor || (t.screens || []).some(s => s && s.name === ctx.output))

    function entryFor(appId) {
        return appId ? DesktopEntries.heuristicLookup(appId) : null
    }
    function keyFor(appId) {
        const e = entryFor(appId)
        return e ? e.id : (appId || "")
    }

    readonly property var entries: {
        const out = []
        const byKey = {}
        for (const id of pinned) {
            const e = DesktopEntries.byId(id)
            if (!e) continue
            const item = { key: e.id, entry: e, windows: [], pinned: true }
            byKey[e.id] = item
            out.push(item)
        }
        for (const t of windows) {
            const key = keyFor(t.appId)
            if (titles) {
                const p = byKey[key]
                if (p && p.windows.length === 0) { p.windows.push(t); continue }
                out.push({ key: key, entry: entryFor(t.appId), windows: [t], pinned: false })
                continue
            }
            if (!byKey[key]) {
                byKey[key] = { key: key, entry: entryFor(t.appId), windows: [], pinned: false }
                out.push(byKey[key])
            }
            byKey[key].windows.push(t)
        }
        return out
    }

    implicitWidth: grid.implicitWidth
    implicitHeight: grid.implicitHeight

    Grid {
        id: grid
        rows: root.vertical ? -1 : 1
        columns: root.vertical ? 1 : -1
        spacing: root.titles ? 4 : 6

        Repeater {
            model: root.entries
            delegate: Item {
                id: button
                required property var modelData
                readonly property var entry: modelData.entry
                readonly property var wins: modelData.windows
                readonly property bool active: wins.some(w => w.activated)
                readonly property string iconPath: entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : ""
                readonly property string title: wins.length ? (wins[0].title || wins[0].appId) : (entry ? entry.name : modelData.key)

                implicitWidth: root.titles ? 168 : root.iconSize + 12
                implicitHeight: root.titles ? root.iconSize + 14 : root.iconSize + 14

                Rectangle {
                    anchors.fill: parent
                    radius: root.titles ? 8 : 10
                    color: button.active ? Theme.accentSoft : area.containsMouse ? Theme.hover
                         : root.titles && button.wins.length ? Theme.alpha(Theme.surface1, 0.5) : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.anim } }
                }

                RowLayout {
                    anchors { fill: parent; leftMargin: root.titles ? 8 : 0; rightMargin: root.titles ? 8 : 0 }
                    spacing: 8

                    Item {
                        implicitWidth: root.iconSize
                        implicitHeight: root.iconSize
                        Layout.alignment: root.titles ? Qt.AlignVCenter : Qt.AlignCenter
                        Layout.fillWidth: !root.titles
                        IconImage {
                            id: img
                            anchors.centerIn: parent
                            implicitSize: root.iconSize
                            source: button.iconPath
                            asynchronous: true
                            visible: status === Image.Ready
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: !img.visible
                            name: "app"
                            size: root.iconSize * 0.8
                            color: Theme.subtext
                        }
                    }
                    Text {
                        visible: root.titles
                        text: button.title
                        color: button.wins.length ? Theme.text : Theme.subtext
                        elide: Text.ElideRight
                        font { family: Theme.font; pixelSize: 11; bold: button.active }
                        Layout.fillWidth: true
                    }
                }

                // Running indicator: under the icon (dock) or the button
                // (taskbar); wide and violet for the focused app.
                Rectangle {
                    visible: button.wins.length > 0
                    anchors.horizontalCenter: root.vertical ? undefined : parent.horizontalCenter
                    anchors.verticalCenter: root.vertical ? parent.verticalCenter : undefined
                    x: root.vertical ? 1 : 0
                    y: root.vertical ? 0 : parent.height - 4
                    width: root.vertical ? 3 : (button.active ? (root.titles ? parent.width - 16 : 14) : (root.titles ? 0 : 5))
                    height: root.vertical ? (button.active ? 14 : 5) : 3
                    radius: 2
                    color: button.active ? Theme.accent : Theme.subtext
                    Behavior on width { NumberAnimation { duration: 160 } }
                }

                MouseArea {
                    id: area
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: mouse => {
                        if (mouse.button === Qt.RightButton) {
                            root.menuFor = button.modelData
                            menu.anchor.item = button
                            menu.visible = true
                            return
                        }
                        if (mouse.button === Qt.MiddleButton || button.wins.length === 0) {
                            if (button.entry) button.entry.execute()
                            return
                        }
                        // Cycle through the app's windows.
                        const i = button.wins.findIndex(w => w.activated)
                        button.wins[(i + 1) % button.wins.length].activate()
                    }
                }
            }
        }
    }

    // ── Right-click menu ────────────────────────────────────────────────
    property var menuFor: null

    function togglePin(item) {
        const list = pinned.slice()
        const i = list.indexOf(item.key)
        if (i >= 0) list.splice(i, 1)
        else if (item.entry) list.push(item.entry.id)
        PanelLayout.setItemOption(ctx.output, ctx.edge, ctx.index, "pinned", list)
    }

    PopupWindow {
        id: menu
        anchor.edges: root.ctx && root.ctx.edge === "bottom" ? Edges.Top : Edges.Bottom
        anchor.gravity: root.ctx && root.ctx.edge === "bottom" ? Edges.Top : Edges.Bottom
        anchor.margins.top: 8
        anchor.margins.bottom: 8
        grabFocus: true
        color: "transparent"
        implicitWidth: 210
        implicitHeight: menuCol.implicitHeight + 12

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: Theme.glassStrong
            border.width: 1
            border.color: Theme.alpha(Theme.text, 0.10)

            Column {
                id: menuCol
                anchors { top: parent.top; left: parent.left; right: parent.right; margins: 6 }
                spacing: 1

                Text {
                    width: parent.width
                    leftPadding: 10
                    topPadding: 6
                    bottomPadding: 4
                    text: root.menuFor && root.menuFor.entry ? root.menuFor.entry.name : (root.menuFor ? root.menuFor.key : "")
                    color: Theme.subtext
                    elide: Text.ElideRight
                    font { family: Theme.font; pixelSize: 10 }
                }
                MenuRow {
                    visible: root.menuFor !== null && root.menuFor.entry !== null
                    label: root.menuFor && root.pinned.includes(root.menuFor.key) ? "Unpin" : "Pin"
                    onActivated: { root.togglePin(root.menuFor); menu.visible = false }
                }
                MenuRow {
                    visible: root.menuFor !== null && root.menuFor.entry !== null
                    label: "New window"
                    onActivated: { root.menuFor.entry.execute(); menu.visible = false }
                }
                MenuRow {
                    visible: root.menuFor !== null && root.menuFor.windows.length > 0
                    label: root.menuFor && root.menuFor.windows.length > 1 ? "Close all " + root.menuFor.windows.length : "Close"
                    danger: true
                    onActivated: { for (const w of root.menuFor.windows) w.close(); menu.visible = false }
                }
            }
        }
    }

    component MenuRow: Rectangle {
        id: mr
        property string label: ""
        property bool danger: false
        signal activated()
        width: menuCol.width
        height: visible ? 30 : 0
        radius: 8
        color: mrArea.containsMouse ? Theme.alpha(danger ? Theme.danger : Theme.accent, 0.18) : "transparent"
        Text {
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: 10 }
            text: mr.label
            color: mr.danger ? Theme.danger : Theme.text
            font { family: Theme.font; pixelSize: 12 }
        }
        MouseArea {
            id: mrArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: mr.activated()
        }
    }
}
