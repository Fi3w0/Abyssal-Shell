import QtQuick
import "../components"
import "../services"

// Claude Code / Codex usage: a small ring per tool filled by its 5-hour
// window (amber past 70%, rose past 90%), a red dot when a service has a
// major incident. Opens the usage panel under the widget.
Item {
    id: root
    property var ctx

    readonly property bool shown: AiUsage.claude !== null || AiUsage.codex !== null
    readonly property bool open: Shell.detail !== null && Shell.detail.page === "usage" && Shell.detail.output === (ctx ? ctx.output : "")

    implicitWidth: row.implicitWidth + 14
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
        spacing: 6
        Repeater {
            model: [{ tag: "C", src: AiUsage.claude }, { tag: "X", src: AiUsage.codex }].filter(m => m.src)
            delegate: Item {
                id: ring
                required property var modelData
                readonly property real used: Math.max(0, AiUsage.used(modelData.src, "5 hours"))
                readonly property color tint: used >= 90 ? Theme.danger : used >= 70 ? Theme.warn : Theme.accent
                width: 18; height: 18
                Canvas {
                    id: canvas
                    anchors.fill: parent
                    property real used: ring.used
                    property color tint: ring.tint
                    onUsedChanged: requestPaint()
                    onTintChanged: requestPaint()
                    onPaint: {
                        const c = getContext("2d")
                        c.reset()
                        c.lineWidth = 2.2
                        c.strokeStyle = Theme.alpha(Theme.text, 0.15)
                        c.beginPath(); c.arc(9, 9, 7.5, 0, 2 * Math.PI); c.stroke()
                        c.strokeStyle = tint
                        c.beginPath(); c.arc(9, 9, 7.5, -Math.PI / 2, -Math.PI / 2 + 2 * Math.PI * Math.min(1, used / 100)); c.stroke()
                    }
                }
                Text {
                    anchors.centerIn: parent
                    text: ring.modelData.tag
                    color: Theme.subtext
                    font { family: Theme.monoFont; pixelSize: 8; bold: true }
                }
            }
        }
    }
    Rectangle {
        visible: AiUsage.trouble
        anchors { right: parent.right; top: parent.top; margins: 3 }
        width: 6; height: 6; radius: 3
        color: Theme.danger
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
