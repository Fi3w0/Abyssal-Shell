import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"

// Claude Code and Codex: how much of the 5-hour and weekly windows is used,
// when each resets, and whether the service is having trouble.
ColumnLayout {
    id: root

    property bool showBack: false
    property bool active: false
    signal back()

    spacing: 8

    onActiveChanged: if (active) AiUsage.refresh()
    property real now: Date.now() / 1000
    Timer { running: root.active; interval: 30000; repeat: true; triggeredOnStart: true; onTriggered: root.now = Date.now() / 1000 }

    function span(sec) {
        sec = Math.max(0, Math.round(sec))
        const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60)
        return d ? d + "d " + h + "h" : h ? h + "h " + m + "m" : m + "m"
    }
    function levelColor(p) {
        return p >= 90 ? Theme.danger : p >= 70 ? Theme.warn : Theme.accent
    }
    function statusColor(ind) {
        return ind === "none" ? Theme.success : ind === "minor" ? Theme.warn : ind === "unknown" ? Theme.overlay : Theme.danger
    }

    PageHeader {
        icon: "gauge"
        title: "AI usage"
        showBack: root.showBack
        onBack: root.back()
    }

    Repeater {
        model: [
            { name: "Claude Code", src: AiUsage.claude, status: AiUsage.status.claude, link: "https://status.claude.com",
              missing: "Use Claude Code once: its status line (scripts/claude-statusline) records the limits." },
            { name: "Codex", src: AiUsage.codex, status: AiUsage.status.openai, link: "https://status.openai.com",
              missing: "No Codex sessions found in ~/.codex/sessions yet." }
        ]
        delegate: Rectangle {
            id: card
            required property var modelData
            readonly property var st: modelData.status || { indicator: "unknown", description: "Checking…" }
            Layout.fillWidth: true
            implicitHeight: col.implicitHeight + 24
            radius: Theme.controlRadius
            color: Theme.alpha(Theme.text, 0.04)
            border.width: 1
            border.color: Theme.hairline

            ColumnLayout {
                id: col
                anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: card.modelData.name
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 13; bold: true }
                    }
                    // Service status; click opens the status page.
                    Row {
                        spacing: 6
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 7; height: 7; radius: 3.5
                            color: root.statusColor(card.st.indicator)
                        }
                        Text {
                            text: card.st.description
                            color: card.st.indicator === "none" ? Theme.subtext : root.statusColor(card.st.indicator)
                            font { family: Theme.font; pixelSize: 10 }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.openUrlExternally(card.modelData.link)
                            }
                        }
                    }
                }

                Text {
                    visible: !card.modelData.src
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    text: card.modelData.missing
                    color: Theme.overlay
                    font { family: Theme.font; pixelSize: 11 }
                }

                Repeater {
                    model: card.modelData.src ? card.modelData.src.windows : []
                    delegate: ColumnLayout {
                        id: win
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: 4
                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: win.modelData.name
                                color: Theme.subtext
                                font { family: Theme.font; pixelSize: 11 }
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: win.modelData.resets_at ? "resets in " + root.span(win.modelData.resets_at - root.now) : "fresh window"
                                color: Theme.overlay
                                font { family: Theme.font; pixelSize: 10 }
                            }
                            Text {
                                text: Math.round(win.modelData.used) + "%"
                                color: root.levelColor(win.modelData.used)
                                font { family: Theme.monoFont; pixelSize: 12; bold: true }
                                Layout.preferredWidth: 38
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: 6
                            radius: 3
                            color: Theme.alpha(Theme.text, 0.08)
                            Rectangle {
                                width: parent.width * Math.min(1, win.modelData.used / 100)
                                height: parent.height
                                radius: 3
                                color: root.levelColor(win.modelData.used)
                                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                            }
                        }
                    }
                }

                Text {
                    visible: !!card.modelData.src && !!card.modelData.src.updated
                    text: card.modelData.src ? "as of your last session, " + root.span(root.now - card.modelData.src.updated) + " ago" : ""
                    color: Theme.overlay
                    font { family: Theme.font; pixelSize: 10 }
                }
            }
        }
    }
}
