import QtQuick
import QtQuick.Layouts
import "../components"
import "../services"

// Notification centre: newest first, grouped by app. Click a notification
// to open it (its default action), use its buttons for other actions, ×
// to dismiss. The bell in the header toggles Do not disturb.
ColumnLayout {
    id: root

    property bool showBack: false
    property bool active: false
    signal back()

    spacing: 2

    onActiveChanged: if (active) Notifications.markRead()
    Connections {
        target: Notifications
        function onHistoryChanged() { if (root.active) Notifications.markRead() }
    }

    // Groups in order of each app's newest notification.
    readonly property var groups: {
        const out = []
        const byApp = {}
        for (const n of Notifications.history) {
            if (!byApp[n.app]) { byApp[n.app] = { app: n.app, items: [] }; out.push(byApp[n.app]) }
            byApp[n.app].items.push(n)
        }
        return out
    }

    // "2m", "1h"… refreshed while shown.
    property real now: Date.now()
    Timer { running: root.active; interval: 30000; repeat: true; triggeredOnStart: true; onTriggered: root.now = Date.now() }
    function ago(ts) {
        const s = Math.max(0, Math.floor((now - ts) / 1000))
        if (s < 60) return "now"
        if (s < 3600) return Math.floor(s / 60) + "m"
        if (s < 86400) return Math.floor(s / 3600) + "h"
        return Math.floor(s / 86400) + "d"
    }

    RowLayout {
        spacing: 8
        Layout.fillWidth: true
        Layout.bottomMargin: 4
        BarButton {
            visible: root.showBack
            implicitWidth: 28; implicitHeight: 28
            icon: "chevron-left"; iconSize: 14
            onClicked: root.back()
        }
        Text {
            text: "Notifications"
            color: Theme.text
            font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
            Layout.fillWidth: true
            Layout.leftMargin: root.showBack ? 0 : 2
        }
        BarButton {
            implicitWidth: 28; implicitHeight: 28
            icon: Notifications.dnd ? "bell-off" : "bell"
            iconSize: 14
            iconColor: Notifications.dnd ? Theme.rose : Theme.subtext
            onClicked: Notifications.dnd = !Notifications.dnd
        }
        TextButton {
            visible: Notifications.history.length > 0
            text: "Clear"
            onClicked: Notifications.clear()
        }
    }

    Text {
        visible: Notifications.dnd
        text: "Do not disturb: new notifications arrive here without toasts."
        color: Theme.rose
        wrapMode: Text.WordWrap
        font { family: Theme.font; pixelSize: 10 }
        Layout.fillWidth: true
        Layout.leftMargin: 2
        Layout.bottomMargin: 4
    }

    ColumnLayout {
        visible: Notifications.history.length === 0
        spacing: 8
        Layout.fillWidth: true
        Layout.topMargin: 28
        Layout.bottomMargin: 28
        Icon { name: "bell"; size: 22; stroke: 1.5; color: Theme.overlay; Layout.alignment: Qt.AlignHCenter }
        Text {
            text: "No notifications"
            color: Theme.overlay
            font { family: Theme.font; pixelSize: 11 }
            Layout.alignment: Qt.AlignHCenter
        }
    }

    Flickable {
        visible: Notifications.history.length > 0
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 420)
        contentHeight: list.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: list
            width: parent.width
            spacing: 2

            Repeater {
                model: root.groups
                Column {
                    id: group
                    required property var modelData
                    width: list.width
                    spacing: 2

                    Text {
                        text: group.modelData.app.toUpperCase()
                        color: Theme.overlay
                        font { family: Theme.font; pixelSize: 9; letterSpacing: 1.6 }
                        leftPadding: 10
                        topPadding: 8
                        bottomPadding: 2
                    }
                    Repeater {
                        model: group.modelData.items
                        NotificationCard { width: group.width; page: root }
                    }
                }
            }
        }
    }

    component NotificationCard: Rectangle {
        id: card
        required property var modelData
        property var page: null

        implicitHeight: body.implicitHeight + 20
        radius: 11
        color: hover.hovered ? Theme.alpha(Theme.text, 0.04) : "transparent"

        // On the card itself, so it stays hovered over its own buttons.
        HoverHandler { id: hover }

        MouseArea {
            anchors.fill: parent
            cursorShape: card.modelData.hasDefault ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: if (card.modelData.hasDefault) Notifications.invoke(card.modelData.nid, "default")
        }

        RowLayout {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 10 }
            spacing: 11

            Rectangle {
                implicitWidth: 26
                implicitHeight: 26
                radius: 13
                color: "transparent"
                border.width: 1
                border.color: Theme.alpha(Theme.text, 0.12)
                Layout.alignment: Qt.AlignTop
                AppIcon {
                    id: appIcon
                    anchors.centerIn: parent
                    implicitSize: 16
                    iconName: card.modelData.icon.startsWith("/") || card.modelData.icon.startsWith("file:") ? "" : card.modelData.icon
                    visible: status === Image.Ready
                }
                Text {
                    anchors.centerIn: parent
                    visible: !appIcon.visible
                    text: card.modelData.app.charAt(0).toUpperCase()
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: 10 }
                }
            }

            ColumnLayout {
                spacing: 1
                Layout.fillWidth: true
                RowLayout {
                    spacing: 6
                    Layout.fillWidth: true
                    Text {
                        text: card.modelData.title || card.modelData.app
                        color: Theme.text
                        elide: Text.ElideRight
                        font { family: Theme.font; pixelSize: 12 }
                        Layout.fillWidth: true
                    }
                    Text {
                        visible: !hover.hovered
                        text: card.page ? card.page.ago(card.modelData.ts) : ""
                        color: Theme.overlay
                        font { family: Theme.font; pixelSize: 10 }
                    }
                    BarButton {
                        visible: hover.hovered
                        implicitWidth: 18; implicitHeight: 18
                        icon: "x"; iconSize: 10
                        iconColor: Theme.overlay
                        onClicked: Notifications.remove(card.modelData.nid)
                    }
                }
                Text {
                    visible: card.modelData.body !== ""
                    text: card.modelData.body
                    color: Theme.subtext
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    font { family: Theme.font; pixelSize: 11 }
                    Layout.fillWidth: true
                }
                Image {
                    visible: (card.modelData.image || "") !== "" && status === Image.Ready
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    Layout.preferredHeight: visible ? Math.min(120, width * implicitHeight / Math.max(1, implicitWidth)) : 0
                    source: card.modelData.image || ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 500
                }
                Flow {
                    visible: card.modelData.actions.length > 0
                    spacing: 6
                    Layout.fillWidth: true
                    Layout.topMargin: 6
                    Repeater {
                        model: card.modelData.actions
                        TextButton {
                            required property var modelData
                            text: modelData.text
                            onClicked: Notifications.invoke(card.modelData.nid, modelData.id)
                        }
                    }
                }
            }
        }
    }
}
