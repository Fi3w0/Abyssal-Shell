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

    readonly property var results: {
        const q = query.trim().toLowerCase()
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
        const rows = list.slice(0, 8).map(e => ({ kind: "app", entry: e }))
        if (calc !== "") rows.unshift({ kind: "calc", value: calc })
        return rows
    }

    function activate(row) {
        if (!row) return
        if (row.kind === "calc") {
            Quickshell.clipboardText = row.value
        } else {
            remember(row.entry)
            row.entry.execute()
        }
        Shell.launcherOn = ""
    }

    visible: open
    onOpenChanged: if (open) { search.text = ""; query = ""; selected = 0; search.forceActiveFocus() }
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
        y: Math.round(parent.height * 0.22)
        width: 680
        height: col.implicitHeight + 16
        radius: 22
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
                        text: "Search apps, or type a sum"
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
                    readonly property bool isCalc: modelData.kind === "calc"
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
                            IconImage {
                                id: appIcon
                                anchors.fill: parent
                                asynchronous: true
                                source: !rowItem.isCalc && rowItem.modelData.entry.icon
                                        ? Quickshell.iconPath(rowItem.modelData.entry.icon, true) : ""
                                visible: !rowItem.isCalc && status === Image.Ready
                            }
                            Icon {
                                anchors.centerIn: parent
                                visible: !appIcon.visible
                                name: rowItem.isCalc ? "plus" : "app"
                                size: 22
                                color: rowItem.isCalc ? Theme.cyan : Theme.subtext
                            }
                        }

                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Text {
                                text: rowItem.isCalc ? "= " + rowItem.modelData.value : rowItem.modelData.entry.name
                                color: Theme.text
                                elide: Text.ElideRight
                                font { family: Theme.font; pixelSize: rowItem.isCalc ? 16 : 13; bold: true }
                                Layout.fillWidth: true
                            }
                            Text {
                                readonly property var e: rowItem.isCalc ? null : rowItem.modelData.entry
                                visible: text !== ""
                                text: rowItem.isCalc ? "Enter copies the result"
                                    : (e.genericName || e.comment || "")
                                color: Theme.subtext
                                elide: Text.ElideRight
                                font { family: Theme.font; pixelSize: 10 }
                                Layout.fillWidth: true
                            }
                        }

                        Text {
                            visible: rowItem.current
                            text: rowItem.isCalc ? "copy ↵" : "open ↵"
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
