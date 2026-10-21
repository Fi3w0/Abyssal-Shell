import QtQuick
import Quickshell
import "../components"
import "../services"

// Recognizable provider marks with a small usage underline per tool.
Item {
    id: root
    property var ctx
    readonly property var opts: ctx && ctx.options ? ctx.options : ({})
    readonly property bool vertical: ctx ? ctx.vertical : false

    readonly property var tools: [
        { key: "claude", icon: "claude", name: "Claude Code", src: AiUsage.claude, status: AiUsage.status.claude },
        { key: "codex", icon: "openai", name: "Codex", src: AiUsage.codex, status: AiUsage.status.openai }
    ].filter(t => t.src && (opts.show === undefined || opts.show === "both" || opts.show === t.key))

    readonly property bool shown: tools.length > 0
    readonly property bool open: Shell.detail !== null && Shell.detail.page === "usage" && Shell.detail.output === (ctx ? ctx.output : "")
    readonly property bool weekly: opts.weekly !== false

    implicitWidth: vertical ? 32 : meters.implicitWidth + 12
    implicitHeight: vertical ? meters.implicitHeight + 8 : 28
    readonly property real minimumContentWidth: meters.implicitWidth + 2
    readonly property real minimumContentHeight: meters.implicitHeight + 2

    function reading(src, name) {
        const window = src && src.windows ? src.windows.find(w => w.name === name) : null
        return window && typeof window.used === "number" && Number.isFinite(window.used)
            ? Math.max(0, Math.min(100, window.used)) : null
    }

    function summary(src) {
        const five = reading(src, "5 hours"), week = reading(src, "Week")
        return "5h  " + (five === null ? "unavailable" : Math.round(five) + "% used")
            + "   ·   Week  " + (week === null ? "unavailable" : Math.round(week) + "% used")
    }

    Rectangle {
        anchors.fill: parent
        radius: 9
        color: root.open ? Theme.accentSoft : area.containsMouse ? Theme.hover : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.anim } }
    }

    Grid {
        id: meters
        anchors.centerIn: parent
        columns: root.vertical ? 1 : Math.max(1, root.tools.length)
        spacing: 6

        Repeater {
            model: root.tools
            delegate: Item {
                id: tool
                required property var modelData
                readonly property var used: root.reading(modelData.src, "5 hours")
                readonly property var weekUsed: root.reading(modelData.src, "Week")
                readonly property color tint: used >= 90 ? Theme.danger : used >= 70 ? Theme.warn : Theme.accent
                readonly property string incident: modelData.status ? modelData.status.indicator : "none"
                width: 16
                height: root.weekly ? 23 : 20
                Icon {
                    name: tool.modelData.icon
                    size: 16
                    color: Theme.subtext
                }
                Item {
                    y: 18
                    width: 16
                    height: root.weekly ? 5 : 2
                    // 5-hour window
                    Rectangle {
                        width: parent.width; height: 2; radius: 1
                        color: Theme.alpha(Theme.text, 0.12)
                        Rectangle {
                            width: tool.used === null ? 0 : parent.width * tool.used / 100
                            height: parent.height; radius: 1
                            color: tool.tint
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                        Text {
                            visible: tool.used === null
                            anchors.centerIn: parent
                            text: "—"
                            color: Theme.overlay
                            font.pixelSize: 9
                        }
                    }
                    // Week
                    Rectangle {
                        visible: root.weekly
                        y: 4
                        width: parent.width; height: 1; radius: 0.5
                        color: Theme.alpha(Theme.text, 0.12)
                        Rectangle {
                            width: tool.weekUsed === null ? 0 : parent.width * tool.weekUsed / 100
                            height: parent.height; radius: 0.5
                            color: tool.weekUsed >= 90 ? Theme.danger : tool.weekUsed >= 70 ? Theme.warn : Theme.subtext
                            Behavior on width { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                        }
                        opacity: tool.weekUsed === null ? 0.35 : 1
                    }
                    Rectangle {
                        visible: tool.incident !== "none" && tool.incident !== "unknown"
                        anchors { left: parent.right; top: parent.top; leftMargin: 1; topMargin: -18 }
                        width: 4; height: 4; radius: 2
                        color: tool.incident === "minor" ? Theme.warn : Theme.danger
                    }
                }
            }
        }
    }

    Timer {
        id: hoverDelay
        interval: 450
        onTriggered: hoverCard.visible = true
    }
    PopupWindow {
        id: hoverCard
        anchor.item: root
        anchor.edges: root.ctx && root.ctx.edge === "bottom" ? Edges.Top
            : root.ctx && root.ctx.edge === "left" ? Edges.Right
            : root.ctx && root.ctx.edge === "right" ? Edges.Left : Edges.Bottom
        anchor.gravity: anchor.edges
        anchor.margins { top: 8; bottom: 8; left: 8; right: 8 }
        color: "transparent"
        implicitWidth: hoverContent.implicitWidth + 24
        implicitHeight: hoverContent.implicitHeight + 20

        // Accept every button: Qt (6.8+) turns a click nothing accepted into a
        // context-menu event, and delivering that while the popup's items are
        // being torn down crashed in QQuickItem::mapToScene.
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }

        Rectangle {
            anchors.fill: parent
            color: Theme.glassStrong
            radius: Theme.controlRadius
            border { width: 1; color: Theme.hairline }
            Column {
                id: hoverContent
                anchors { centerIn: parent }
                spacing: 10
                Repeater {
                    model: root.tools
                    delegate: Column {
                        required property var modelData
                        spacing: 3
                        Text {
                            text: modelData.name
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 11; bold: true }
                        }
                        Text {
                            text: root.summary(modelData.src)
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: 10 }
                        }
                    }
                }
            }
        }
    }
    onOpenChanged: { hoverDelay.stop(); hoverCard.visible = false }
    onVisibleChanged: if (!visible) { hoverDelay.stop(); hoverCard.visible = false }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onEntered: if (!root.open && !Shell.editing) hoverDelay.restart()
        onExited: { hoverDelay.stop(); hoverCard.visible = false }
        onClicked: {
            hoverDelay.stop()
            hoverCard.visible = false
            const p = root.mapToItem(null, root.width / 2, root.height / 2)
            Shell.toggleDetail(root.ctx.output, root.ctx.edge, "usage", root.ctx.vertical ? p.y : p.x, root.ctx.thickness)
        }
    }
}
