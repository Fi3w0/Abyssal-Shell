import QtQuick
import "../components"
import "../services"

// Claude Code / Codex usage, in the bar's CPU/GPU style: a short label and
// the 5-hour window's percentage (accent, amber past 70%, rose past 90%),
// with the weekly window as a thin line underneath. Close to the limit the
// number turns into the time until it resets. A dot marks a service
// incident. Opens the usage panel under the widget.
Item {
    id: root
    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})

    readonly property var tools: [
        { key: "claude", tag: "CC", src: AiUsage.claude, status: AiUsage.status.claude },
        { key: "codex", tag: "CX", src: AiUsage.codex, status: AiUsage.status.openai }
    ].filter(t => t.src && (opts.show === undefined || opts.show === "both" || opts.show === t.key))

    readonly property bool shown: tools.length > 0
    readonly property bool open: Shell.detail !== null && Shell.detail.page === "usage" && Shell.detail.output === (ctx ? ctx.output : "")
    readonly property bool weekly: opts.weekly !== false

    // Seconds, refreshed while visible, for the reset countdown.
    property real now: Date.now() / 1000
    Timer { running: root.visible; interval: 30000; repeat: true; triggeredOnStart: true; onTriggered: root.now = Date.now() / 1000 }

    implicitWidth: row.implicitWidth + 16
    implicitHeight: 28

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.open ? Theme.accentSoft : area.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 12

        Repeater {
            model: root.tools
            delegate: Row {
                id: tool
                required property var modelData
                required property int index
                readonly property var five: modelData.src.windows.find(w => w.name === "5 hours") || null
                readonly property var week: modelData.src.windows.find(w => w.name === "Week") || null
                readonly property real used: five ? five.used : 0
                readonly property bool capped: used >= 95 && five && five.resets_at
                readonly property color tint: used >= 90 ? Theme.danger : used >= 70 ? Theme.warn : Theme.accent
                readonly property string incident: modelData.status ? modelData.status.indicator : "none"
                spacing: 5

                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    implicitWidth: tagText.implicitWidth
                    implicitHeight: tagText.implicitHeight
                    Text {
                        id: tagText
                        text: tool.modelData.tag
                        color: Theme.overlay
                        font { family: Theme.monoFont; pixelSize: 10; bold: true; letterSpacing: 0.5 }
                    }
                    // Service incident (minor: amber, major: rose).
                    Rectangle {
                        visible: tool.incident !== "none" && tool.incident !== "unknown"
                        anchors { left: parent.right; top: parent.top; leftMargin: 1; topMargin: -3 }
                        width: 5; height: 5; radius: 2.5
                        color: tool.incident === "minor" ? Theme.warn : Theme.danger
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2
                    Text {
                        id: value
                        text: tool.capped ? root.span(tool.five.resets_at - root.now) : Math.round(tool.used) + "%"
                        color: tool.tint
                        font { family: Theme.monoFont; pixelSize: 11; bold: true }
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                    // Weekly window: a thin track under the number.
                    Rectangle {
                        visible: root.weekly && tool.week !== null
                        width: Math.max(value.implicitWidth, 22)
                        height: 2
                        radius: 1
                        color: Theme.alpha(Theme.text, 0.12)
                        Rectangle {
                            width: parent.width * Math.min(1, (tool.week ? tool.week.used : 0) / 100)
                            height: parent.height
                            radius: 1
                            color: (tool.week ? tool.week.used : 0) >= 90 ? Theme.danger : Theme.subtext
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                    }
                }
            }
        }
    }

    function span(sec) {
        sec = Math.max(0, Math.round(sec))
        const h = Math.floor(sec / 3600), m = Math.floor(sec % 3600 / 60)
        return h ? h + "h" + String(m).padStart(2, "0") : m + "m"
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            const p = root.mapToItem(null, root.width / 2, root.height / 2)
            Shell.toggleDetail(root.ctx.output, root.ctx.edge, "usage", root.ctx.vertical ? p.y : p.x, root.ctx.thickness)
        }
    }
}
