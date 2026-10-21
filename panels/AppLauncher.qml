import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../services"

// Spotlight / KRunner-style launcher: one search field in the upper third
// of the monitor it was opened on, a ranked list under it.
//   empty field   your most used apps
//   typing        apps ranked by name, word starts, generic name, keywords;
//                 apps you launch often rank higher
//   2+2*3         a calculator row; Enter copies the result
//   lock, reboot  shell actions by name: lock, log out, sleep, reboot, shut
//                 down, wallpaper, updates, clipboard, edit panels, and
//                 "theme <name>" to switch themes
//   >command      runs it in your terminal
// Up/Down move, Enter opens, Esc or a click outside closes.
PanelWindow {
    id: root

    // Passed in from shell.qml: deriving visibility from the window's own
    // `screen` makes a binding loop.
    required property string output
    readonly property bool open: Shell.launcherOn === output
    property string query: ""
    property int selected: 0

    readonly property var apps: DesktopEntries.applications.values.filter(e => !e.noDisplay)

    // ── Launch counts, kept across sessions ─────────────────────────────
    property var usage: ({})
    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        printErrors: false
        onLoaded: { try { root.usage = JSON.parse(text()) } catch (e) { root.usage = {} } }
    }
    function used(entry) {
        return usage[entry.id] || 0
    }
    function remember(entry) {
        const next = Object.assign({}, usage)
        next[entry.id] = (next[entry.id] || 0) + 1
        usage = next
        usageFile.setText(JSON.stringify(next))
    }

    // ── Calculator ──────────────────────────────────────────────────────
    // Only digits, operators, dots and brackets ever reach Function().
    readonly property string calc: {
        const q = query.trim()
        if (!/^[0-9+\-*/%^().\s]+$/.test(q) || !/[+\-*/%^]/.test(q) || !/[0-9]/.test(q)) return ""
        try {
            const v = Function('"use strict"; return (' + q.replace(/\^/g, "**") + ")")()
            return typeof v === "number" && isFinite(v) ? String(Math.round(v * 1e10) / 1e10) : ""
        } catch (e) {
            return ""
        }
    }

    // ── Ranking ─────────────────────────────────────────────────────────
    function score(e, q) {
        const name = e.name.toLowerCase()
        let s = 0
        if (name === q) s = 120
        else if (name.startsWith(q)) s = 100
        else if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) s = 80
        else if (name.includes(q)) s = 60
        else if ((e.genericName || "").toLowerCase().includes(q)) s = 45
        else if ((e.keywords || []).some(k => k.toLowerCase().startsWith(q))) s = 40
        else if ((e.comment || "").toLowerCase().includes(q) || (e.id || "").toLowerCase().includes(q)) s = 25
        if (s === 0) return 0
        return s + Math.min(20, used(e) * 2)
    }

    // ── Shell actions, found by name ────────────────────────────────────
    readonly property var actions: [
        { title: "Abyssal Settings", icon: "settings", words: "settings preferences config theme keybinds autostart account", detail: "Configure the desktop", run: () => Shell.settings() },
        { title: "Lock", icon: "lock", words: "lock screen", run: () => Shell.lock() },
        { title: "Log out", icon: "logout", words: "logout log out exit quit session tidewm", run: () => Quickshell.execDetached(["tidectl", "quit"]) },
        { title: "Sleep", icon: "sleep", words: "sleep suspend", run: () => Quickshell.execDetached(["systemctl", "suspend"]) },
        { title: "Reboot", icon: "reboot", words: "reboot restart", run: () => Quickshell.execDetached(["systemctl", "reboot"]) },
        { title: "Shut down", icon: "power", words: "shut down shutdown power off poweroff", run: () => Quickshell.execDetached(["systemctl", "poweroff"]) },
        { title: "Wallpaper", icon: "image", words: "wallpaper background picker", detail: "Pick a wallpaper for this monitor", run: () => Shell.toggleWallpaperPicker(root.output) },
        { title: "Check for updates", icon: "package", words: "updates upgrade packages check", run: () => Updates.check(false) },
        { title: "Clipboard history", icon: "clipboard", words: "clipboard copy paste history", run: () => Shell.openPage("clipboard") },
        { title: "Edit panels", icon: "sliders", words: "edit panels bar layout widgets", run: () => Shell.setEditing(true) }
    ].concat(Themes.ids.map(id => ({
        title: "Theme: " + Themes.name(id), icon: "palette", words: "theme " + id.replace(/-/g, " ") + " " + Themes.name(id).toLowerCase(),
        detail: Themes.activeId === id ? "In use" : "Switch the shell's colours",
        run: () => { Appearance.set("fromWallpaper", false); Appearance.set("theme", id) }
    })))
    function actionScore(a, q) {
        const words = (a.title + " " + a.words).toLowerCase()
        if (a.title.toLowerCase().startsWith(q)) return 3
        if (words.split(/\s+/).some(w => w.startsWith(q))) return 2
        return q.length >= 3 && words.includes(q) ? 1 : 0
    }

    readonly property var results: {
        const raw = query.trim()
        // ">command": run it in a terminal.
        if (raw.startsWith(">")) {
            const cmd = raw.slice(1).trim()
            return cmd ? [{ kind: "command", title: cmd, detail: "Run in a terminal", icon: "terminal", hint: "run ↵", cmd: cmd }] : []
        }
        const q = raw.toLowerCase()
        let list
        if (q === "") {
            list = apps.filter(e => used(e) > 0).sort((a, b) => used(b) - used(a))
            if (list.length < 6) list = list.concat(apps.filter(e => used(e) === 0)
                                                        .sort((a, b) => a.name.localeCompare(b.name))
                                                        .slice(0, 6 - list.length))
        } else {
            list = apps.map(e => ({ e: e, s: score(e, q) }))
                       .filter(x => x.s > 0)
                       .sort((a, b) => b.s - a.s || a.e.name.localeCompare(b.e.name))
                       .map(x => x.e)
        }
        const rows = list.slice(0, 8).map(e => ({ kind: "app", entry: e, title: e.name,
            detail: e.genericName || e.comment || "", hint: "open ↵" }))
        if (q.length >= 2) {
            const acts = actions.map(a => ({ a: a, s: actionScore(a, q) })).filter(x => x.s > 0)
                .sort((x, y) => y.s - x.s).slice(0, 4)
                .map(x => ({ kind: "action", title: x.a.title, detail: x.a.detail || "", icon: x.a.icon, hint: "run ↵", run: x.a.run, strong: x.s === 3 }))
            // A name that starts with what you typed comes before the apps.
            rows.unshift(...acts.filter(r => r.strong))
            rows.push(...acts.filter(r => !r.strong))
        }
        if (calc !== "") rows.unshift({ kind: "calc", value: calc, title: "= " + calc, detail: "Enter copies the result", icon: "plus", hint: "copy ↵" })
        return rows.slice(0, 9)
    }

    function activate(row) {
        if (!row) return
        if (row.kind === "calc") {
            Quickshell.clipboardText = row.value
        } else if (row.kind === "action") {
            Shell.launcherOn = ""
            row.run()
            return
        } else if (row.kind === "command") {
            Quickshell.execDetached([Quickshell.shellPath("scripts/terminal"), "sh", "-c",
                row.cmd + "; printf '\\n\\033[2m[done, Enter closes]\\033[0m'; read -r _"])
        } else {
            remember(row.entry)
            row.entry.execute()
        }
        Shell.launcherOn = ""
    }

    // Up until the closing animation is done.
    property bool shown: false
    visible: shown
    onOpenChanged: if (open) { shown = true; search.text = ""; query = ""; selected = 0; search.forceActiveFocus() }
    WlrLayershell.namespace: "abyssal-launcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    MouseArea { anchors.fill: parent; onClicked: Shell.launcherOn = "" }

    Rectangle {
        id: card
        anchors.horizontalCenter: parent.horizontalCenter
        // Fades in while rising slightly; closing reverses it.
        property real t: root.open ? 1 : 0
        Behavior on t { NumberAnimation { duration: root.open ? 220 : 140; easing.type: Easing.OutCubic } }
        onTChanged: if (t === 0 && !root.open) root.shown = false
        opacity: t
        scale: 0.97 + 0.03 * t
        y: Math.round(parent.height * 0.22 + (1 - t) * 14)
        width: 680
        height: col.implicitHeight + 16
        radius: Theme.popupRadius
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.alpha(Theme.text, 0.10)
        MouseArea { anchors.fill: parent }

        Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

        ColumnLayout {
            id: col
            anchors { top: parent.top; left: parent.left; right: parent.right; margins: 8 }
            spacing: 6

            // Search field
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                Layout.leftMargin: 14
                Layout.rightMargin: 14
                spacing: 14

                Icon { name: "search"; size: 20; color: Theme.accent }
                TextInput {
                    id: search
                    Layout.fillWidth: true
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 20 }
                    clip: true
                    focus: true
                    onTextChanged: { root.query = text; root.selected = 0 }
                    Keys.onEscapePressed: Shell.launcherOn = ""
                    Keys.onReturnPressed: root.activate(root.results[root.selected])
                    Keys.onEnterPressed: root.activate(root.results[root.selected])
                    Keys.onDownPressed: root.selected = Math.min(root.results.length - 1, root.selected + 1)
                    Keys.onUpPressed: root.selected = Math.max(0, root.selected - 1)
                    Keys.onTabPressed: root.selected = (root.selected + 1) % Math.max(1, root.results.length)
                    Text {
                        visible: search.text === ""
                        text: "Search apps and actions, a sum, or >command"
                        color: Theme.overlay
                        font: search.font
                    }
                }
            }

            Rectangle {
                visible: root.results.length > 0
                Layout.fillWidth: true
                implicitHeight: 1
                color: Theme.hairline
            }

            Text {
                visible: root.query.trim() === "" && root.results.length > 0
                text: Object.keys(root.usage).length ? "Most used" : "Apps"
                color: Theme.overlay
                font { family: Theme.font; pixelSize: 10 }
                Layout.leftMargin: 14
                Layout.topMargin: 2
            }

            Repeater {
                model: root.results
                delegate: Rectangle {
                    id: rowItem
                    required property var modelData
                    required property int index
                    readonly property bool isApp: modelData.kind === "app"
                    readonly property bool current: index === root.selected

                    Layout.fillWidth: true
                    implicitHeight: 52
                    radius: 14
                    color: current ? Theme.accentSoft : rowArea.containsMouse ? Theme.hover : "transparent"
                    border.width: current ? 1 : 0
                    border.color: Theme.alpha(Theme.accent, 0.45)

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 14 }
                        spacing: 14

                        Item {
                            implicitWidth: 32
                            implicitHeight: 32
                            AppIcon {
                                id: appIcon
                                anchors.fill: parent
                                asynchronous: true
                                iconName: rowItem.isApp ? rowItem.modelData.entry.icon : ""
                                visible: rowItem.isApp && status === Image.Ready
                            }
                            Icon {
                                anchors.centerIn: parent
                                visible: !appIcon.visible
                                name: rowItem.isApp ? "app" : rowItem.modelData.icon
                                size: 22
                                color: rowItem.isApp ? Theme.subtext : rowItem.modelData.kind === "calc" ? Theme.cyan : Theme.accent
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Text {
                                text: rowItem.modelData.title
                                color: Theme.text
                                elide: Text.ElideRight
                                font { family: rowItem.modelData.kind === "command" ? Theme.monoFont : Theme.font; pixelSize: rowItem.modelData.kind === "calc" ? 16 : 13; bold: true }
                                Layout.fillWidth: true
                            }
                            Text {
                                visible: text !== ""
                                text: rowItem.modelData.detail
                                color: Theme.subtext
                                elide: Text.ElideRight
                                font { family: Theme.font; pixelSize: 10 }
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            visible: rowItem.current
                            text: rowItem.modelData.hint
                            color: Theme.accent
                            font { family: Theme.font; pixelSize: 10 }
                        }
                    }

                    MouseArea {
                        id: rowArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.selected = rowItem.index
                        onClicked: root.activate(rowItem.modelData)
                    }
                }
            }

            Text {
                visible: root.query.trim() !== "" && root.results.length === 0
                text: "Nothing matches “" + root.query.trim() + "”"
                color: Theme.overlay
                font { family: Theme.font; pixelSize: 12 }
                Layout.leftMargin: 14
                Layout.bottomMargin: 8
            }
        }
    }
}
