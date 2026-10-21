import QtQuick
import QtQuick.Layouts
import "../components"
import "../services"

// Clipboard history: type to search, ↑/↓ to move, Enter (or click) copies
// the entry back and closes, Ctrl+P pins, Delete removes. Pinned entries
// stay on top and survive Clear.
ColumnLayout {
    id: root

    property bool showBack: false
    property bool active: false
    property Item dragTarget: null
    signal back()

    spacing: 4

    property int selected: 0
    readonly property var shown: {
        const q = search.text.trim().toLowerCase()
        const list = Clipboard.entries.filter(e => !q || (e.kind === "text" && e.preview.toLowerCase().includes(q)))
        return list.filter(e => e.pinned).concat(list.filter(e => !e.pinned))
    }
    onShownChanged: selected = Math.min(selected, Math.max(0, shown.length - 1))
    onActiveChanged: if (active) { search.text = ""; selected = 0; search.forceActiveFocus() }

    // "2m", "1h"… refreshed while shown.
    property real now: Date.now()
    Timer { running: root.active; interval: 30000; repeat: true; triggeredOnStart: true; onTriggered: root.now = Date.now() }
    function ago(ts) {
        const s = Math.max(0, Math.floor((now - ts) / 1000))
        if (s < 60) return "just now"
        if (s < 3600) return Math.floor(s / 60) + " min"
        if (s < 86400) return Math.floor(s / 3600) + " h"
        return Math.floor(s / 86400) + " d"
    }

    function pick(e) {
        if (!e) return
        Clipboard.copy(e)
        Shell.detail = null
    }

    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Layout.bottomMargin: 2
        Item {
            Layout.fillWidth: true
            implicitHeight: 32
            Row {
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                spacing: 8
                Icon { name: "clipboard"; size: 16; stroke: 1.7; color: Theme.subtext }
                Text {
                    text: "Clipboard"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
                }
            }
            Icon {
                visible: root.dragTarget !== null
                anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 4 }
                name: "grip"
                size: 14
                color: Theme.overlay
            }
            MouseArea {
                anchors.fill: parent
                enabled: root.dragTarget !== null
                cursorShape: pressed ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                preventStealing: true
                drag.target: root.dragTarget
                drag.minimumX: 8
                drag.minimumY: 8
                drag.maximumX: root.dragTarget ? Math.max(8, root.dragTarget.parent.width - root.dragTarget.width - 8) : 8
                drag.maximumY: root.dragTarget ? Math.max(8, root.dragTarget.parent.height - root.dragTarget.height - 8) : 8
            }
        }
        TextButton {
            visible: Clipboard.entries.some(e => !e.pinned)
            text: "Clear"
            icon: "trash"
            onClicked: Clipboard.clear()
        }
    }

    // Search
    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.rightMargin: 4
        Icon { name: "search"; size: 13; color: Theme.overlay }
        TextInput {
            id: search
            Layout.fillWidth: true
            color: Theme.text
            clip: true
            selectByMouse: true
            font { family: Theme.font; pixelSize: 12 }
            Text {
                visible: !search.text
                text: "Search history"
                color: Theme.overlay
                font: search.font
            }
            Keys.onUpPressed: root.selected = Math.max(0, root.selected - 1)
            Keys.onDownPressed: root.selected = Math.min(root.shown.length - 1, root.selected + 1)
            Keys.onReturnPressed: root.pick(root.shown[root.selected])
            Keys.onEnterPressed: root.pick(root.shown[root.selected])
            Keys.onEscapePressed: Shell.detail = null
            Keys.onPressed: event => {
                const e = root.shown[root.selected]
                if (!e) return
                if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) { Clipboard.togglePin(e); event.accepted = true }
                else if (event.key === Qt.Key_Delete) { Clipboard.remove(e); event.accepted = true }
            }
        }
    }
    Rectangle { implicitHeight: 1; Layout.fillWidth: true; color: Theme.hairline; Layout.bottomMargin: 2 }

    ColumnLayout {
        visible: root.shown.length === 0
        spacing: 8
        Layout.fillWidth: true
        Layout.topMargin: 22
        Layout.bottomMargin: 22
        Icon { name: "clipboard"; size: 22; stroke: 1.5; color: Theme.overlay; Layout.alignment: Qt.AlignHCenter }
        Text {
            text: search.text ? "Nothing matches" : "Copied text and images show up here"
            color: Theme.overlay
            font { family: Theme.font; pixelSize: 11 }
            Layout.alignment: Qt.AlignHCenter
        }
    }

    ListView {
        id: list
        visible: root.shown.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 400)
        clip: true
        spacing: 2
        boundsBehavior: Flickable.StopAtBounds
        model: root.shown
        currentIndex: root.selected
        highlightMoveDuration: 120

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: index === root.selected
            width: list.width
            implicitHeight: modelData.kind === "image" ? 58 : 42
            radius: 10
            color: current ? Theme.alpha(Theme.accent, 0.08) : hover.hovered ? Theme.alpha(Theme.text, 0.04) : "transparent"

            HoverHandler { id: hover }

            // Selection mark on the left edge.
            Rectangle {
                visible: row.current
                anchors { left: parent.left; verticalCenter: parent.verticalCenter }
                width: 2
                height: parent.height / 2
                radius: 1
                color: Theme.accent
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.pick(row.modelData)
            }

            RowLayout {
                anchors { fill: parent; leftMargin: 10; rightMargin: 8 }
                spacing: 10

                Text {
                    visible: row.modelData.kind === "text"
                    text: "TXT"
                    color: Theme.overlay
                    horizontalAlignment: Text.AlignHCenter
                    font { family: Theme.font; pixelSize: 9; letterSpacing: 1 }
                    Layout.preferredWidth: 40
                }
                Rectangle {
                    visible: row.modelData.kind === "image"
                    implicitWidth: 64
                    implicitHeight: 42
                    radius: 7
                    color: Theme.surface1
                    clip: true
                    Image {
                        anchors.fill: parent
                        source: row.modelData.kind === "image" ? "file://" + row.modelData.file : ""
                        sourceSize.width: 128
                        sourceSize.height: 84
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }
                ColumnLayout {
                    spacing: 0
                    Layout.fillWidth: true
                    Text {
                        text: row.modelData.kind === "image" ? "Image" : row.modelData.preview
                        color: Theme.text
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        font { family: Theme.font; pixelSize: 12 }
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.ago(row.modelData.ts)
                        color: Theme.overlay
                        font { family: Theme.font; pixelSize: 10 }
                    }
                }
                BarButton {
                    visible: row.modelData.pinned || hover.hovered
                    implicitWidth: 24; implicitHeight: 24
                    icon: "pin"
                    iconSize: 12
                    iconColor: row.modelData.pinned ? Theme.warn : Theme.overlay
                    onClicked: Clipboard.togglePin(row.modelData)
                }
                BarButton {
                    visible: hover.hovered
                    implicitWidth: 24; implicitHeight: 24
                    icon: "trash"
                    iconSize: 12
                    iconColor: Theme.overlay
                    onClicked: Clipboard.remove(row.modelData)
                }
            }
        }
    }

    RowLayout {
        spacing: 12
        Layout.leftMargin: 4
        Layout.topMargin: 4
        Repeater {
            model: [["↑↓", "move"], ["Enter", "copy"], ["Ctrl P", "pin"], ["Del", "delete"]]
            RowLayout {
                required property var modelData
                spacing: 5
                Rectangle {
                    implicitWidth: keyText.implicitWidth + 10
                    implicitHeight: 16
                    radius: 4
                    color: "transparent"
                    border.width: 1
                    border.color: Theme.alpha(Theme.text, 0.14)
                    Text { id: keyText; anchors.centerIn: parent; text: modelData[0]; color: Theme.subtext; font { family: Theme.font; pixelSize: 9 } }
                }
                Text { text: modelData[1]; color: Theme.overlay; font { family: Theme.font; pixelSize: 10 } }
            }
        }
    }
}
