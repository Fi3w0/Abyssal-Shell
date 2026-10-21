import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"

// Package updates (services/Updates.qml): grouped by source, important ones
// (kernel, drivers, toolchain…) first and tagged, then what you selected,
// then dependencies. Only the part of each version that changes is lit.
// Update all / Sync open a terminal; the list refreshes when it closes.
ColumnLayout {
    id: root

    property bool showBack: false
    property bool active: false
    signal back()

    spacing: 6

    property string filter: "all"   // all | important | explicit
    readonly property bool hasReasons: Updates.updates.some(u => u.reason)

    readonly property var groups: Updates.sources.map(s => {
        const items = Updates.updates.filter(u => u.source === s.id
            && (filter === "all" || (filter === "important" ? u.important : u.reason === "explicit")))
        items.sort((a, b) => (b.important - a.important)
            || ((a.reason === "dependency") - (b.reason === "dependency"))
            || a.name.localeCompare(b.name))
        return { source: s, items: items }
    }).filter(g => g.items.length || g.source.error)

    // "5 h ago", refreshed while shown.
    property real now: Date.now()
    Timer { running: root.active; interval: 60000; repeat: true; triggeredOnStart: true; onTriggered: root.now = Date.now() }
    function ago(sec) {
        if (!sec) return ""
        const m = Math.max(0, Math.floor((now / 1000 - sec) / 60))
        return m < 1 ? "just now" : m < 60 ? m + " min ago" : m < 48 * 60 ? Math.floor(m / 60) + " h ago" : Math.floor(m / 1440) + " days ago"
    }

    // [same, changed] of the new version against the old one, cut at a
    // separator so "7.2.9 → 7.2.12" lights "12", not "2".
    function split(oldV, newV) {
        let i = 0
        while (i < oldV.length && i < newV.length && oldV[i] === newV[i]) i++
        while (i > 0 && !".-_:+~".includes(newV[i - 1])) i--
        return [newV.slice(0, i), newV.slice(i)]
    }

    RowLayout {
        Layout.fillWidth: true
        PageHeader {
            icon: "package"
            title: "Updates"
            showBack: root.showBack
            onBack: root.back()
        }
        BarButton { icon: "sliders"; onClicked: Shell.openPage("update-settings") }
    }

    // Count, last sync, news, refresh.
    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 4
        spacing: 8
        Text {
            Layout.fillWidth: true
            elide: Text.ElideRight
            text: Updates.checking ? "Checking…"
                : Updates.busy ? "Waiting: " + Updates.busy
                : (Updates.result.unchecked ? "Check for updates" : Updates.count ? Updates.count + (Updates.count === 1 ? " update" : " updates") : "Up to date")
                  + (Updates.synced ? " · synced " + root.ago(Updates.synced) : "")
            color: Theme.subtext
            font { family: Theme.font; pixelSize: 11 }
        }
        Rectangle {
            visible: Updates.news > 0
            implicitWidth: newsText.implicitWidth + 14
            implicitHeight: 20
            radius: 10
            color: Theme.alpha(Theme.warn, 0.16)
            Text {
                id: newsText
                anchors.centerIn: parent
                text: Updates.news + " news"
                color: Theme.warn
                font { family: Theme.font; pixelSize: 10; bold: true }
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Updates.news > 0 && Quickshell.execDetached([Quickshell.shellPath("scripts/terminal"), "sh", "-c", "eselect news read new | ${PAGER:-less}"])
            }
        }
        BarButton {
            icon: "refresh"
            iconSize: 15
            implicitWidth: 26
            implicitHeight: 26
            onClicked: Updates.check(false)
            RotationAnimator on rotation {
                running: Updates.checking
                from: 0; to: 360; duration: 900
                loops: Animation.Infinite
                onRunningChanged: if (!running) parent.rotation = 0
            }
        }
    }

    Segmented {
        visible: Updates.count > 0
        Layout.fillWidth: true
        uniform: true
        options: [{ value: "all", label: "All" }, { value: "important", label: "Important" }]
            .concat(root.hasReasons ? [{ value: "explicit", label: "Selected" }] : [])
        value: root.filter
        onPicked: v => root.filter = v
    }

    // Up to date
    ColumnLayout {
        visible: Updates.count === 0 && !Updates.errors && !Updates.result.unchecked
        Layout.fillWidth: true
        Layout.topMargin: 18
        Layout.bottomMargin: 18
        spacing: 8
        Icon { Layout.alignment: Qt.AlignHCenter; name: "check"; size: 26; color: Theme.success }
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Updates.checking ? "Looking for updates…" : "Everything is up to date"
            color: Theme.subtext
            font { family: Theme.font; pixelSize: 12 }
        }
    }

    Flickable {
        visible: root.groups.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(list.implicitHeight, 420)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: root.groups
                delegate: ColumnLayout {
                    id: group
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: 2

                    SectionLabel {
                        text: group.modelData.source.name + " · " + group.modelData.items.length
                    }
                    Text {
                        visible: group.modelData.source.error !== ""
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        wrapMode: Text.Wrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                        text: group.modelData.source.error
                        color: Theme.danger
                        font { family: Theme.monoFont; pixelSize: 10 }
                    }

                    Repeater {
                        model: group.modelData.items
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            readonly property var parts: root.split(modelData.old, modelData.new)
                            readonly property string category: modelData.name.includes("/") ? modelData.name.replace(/\/.*$/, "/") : ""
                            Layout.fillWidth: true
                            implicitHeight: rowCol.implicitHeight + 12
                            radius: Theme.controlRadius / 2
                            color: rowArea.containsMouse ? Theme.hover : "transparent"

                            ColumnLayout {
                                id: rowCol
                                anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: 8; rightMargin: 8 }
                                spacing: 1

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6
                                    Rectangle {
                                        visible: row.modelData.important
                                        implicitWidth: 6; implicitHeight: 6; radius: 3
                                        color: Theme.rose
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideMiddle
                                        textFormat: Text.StyledText
                                        text: "<font color='" + Theme.overlay + "'>" + row.category + "</font>"
                                            + row.modelData.name.replace(/^.*\//, "")
                                        color: row.modelData.important ? Theme.rose : Theme.text
                                        font { family: Theme.font; pixelSize: 12; bold: true }
                                    }
                                    Text {
                                        textFormat: Text.StyledText
                                        text: "<font color='" + Theme.overlay + "'>" + row.modelData.old + " → </font>"
                                            + "<font color='" + Theme.subtext + "'>" + row.parts[0] + "</font>"
                                            + "<font color='" + Theme.accent + "'><b>" + row.parts[1] + "</b></font>"
                                        font { family: Theme.monoFont; pixelSize: 11 }
                                    }
                                }
                                Text {
                                    Layout.fillWidth: true
                                    Layout.leftMargin: row.modelData.important ? 12 : 0
                                    elide: Text.ElideRight
                                    text: [row.modelData.reason === "dependency" ? "dependency" : "",
                                           row.modelData.repo, row.modelData.desc].filter(s => s).join(" · ")
                                    color: Theme.overlay
                                    font { family: Theme.font; pixelSize: 10 }
                                }
                            }
                            MouseArea { id: rowArea; anchors.fill: parent; hoverEnabled: true }
                        }
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: 4
        spacing: 6
        Item { Layout.fillWidth: true }
        TextButton {
            visible: Updates.canSync
            text: "Sync"
            icon: "refresh"
            onClicked: Updates.sync()
        }
        TextButton {
            visible: Updates.count > 0
            text: Updates.upgrading ? "Updating…" : "Update all"
            icon: "package"
            accent: true
            onClicked: Updates.upgrade([])
        }
    }
}
