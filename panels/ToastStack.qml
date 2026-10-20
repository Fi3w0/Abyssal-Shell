import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../services"

// Toasts for one monitor. A notification only shows on the monitor you are
// working on (the focused window's output, else the first screen).
PanelWindow {
    id: root

    WlrLayershell.namespace: "abyssal-toast"
    WlrLayershell.layer: WlrLayer.Overlay

    // Top-right; bars' exclusive zones push it clear of them on its own.
    anchors.top: true
    anchors.right: true
    margins.top: 10
    margins.right: 10
    exclusiveZone: 0
    implicitWidth: 340
    implicitHeight: Math.max(col.implicitHeight + 8, 1)
    color: "transparent"
    visible: toastModel.count > 0

    ListModel { id: toastModel }

    function close(tid) {
        for (let i = 0; i < toastModel.count; i++)
            if (toastModel.get(i).tid === tid) { toastModel.setProperty(i, "closing", true); break }
    }

    Connections {
        target: Notifications
        function onToast(item) {
            const here = root.screen ? root.screen.name : ""
            const target = Tide.focusedOutput !== "" ? Tide.focusedOutput : (Quickshell.screens[0]?.name ?? "")
            if (here !== target) return
            toastModel.append({ tid: item.nid, app: item.app, title: item.title, body: item.body, icon: item.icon, closing: false })
            while (toastModel.count > Notifications.maxToasts) toastModel.remove(0)
        }
    }

    ColumnLayout {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 4 }
        spacing: 8

        Repeater {
            model: toastModel
            delegate: Rectangle {
                id: toast
                required property var model
                required property int index
                property bool entered: false

                Layout.fillWidth: true
                implicitHeight: row.implicitHeight + 24
                radius: 16
                color: Theme.glassStrong
                border.width: 1
                border.color: Theme.hairline
                opacity: model.closing ? 0 : (entered ? 1 : 0)
                x: model.closing ? width + 28 : 0

                Component.onCompleted: entered = true
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.InCubic } }
                Behavior on opacity { NumberAnimation { duration: toast.model.closing ? 180 : 260; easing.type: toast.model.closing ? Easing.InCubic : Easing.OutCubic } }

                // Lifetime, paused while the pointer is on the toast.
                Timer {
                    interval: Notifications.toastDuration
                    running: !toast.model.closing && !hover.containsMouse
                    onTriggered: root.close(toast.model.tid)
                }
                Timer {
                    interval: 240
                    running: toast.model.closing
                    onTriggered: if (toast.index >= 0 && toast.index < toastModel.count) toastModel.remove(toast.index)
                }

                MouseArea { id: hover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

                RowLayout {
                    id: row
                    anchors { fill: parent; margins: 12 }
                    spacing: 11

                    Rectangle {
                        implicitWidth: 36
                        implicitHeight: 36
                        radius: 11
                        color: Theme.alpha(Theme.accent, 0.18)
                        Layout.alignment: Qt.AlignTop

                        IconImage {
                            id: appIcon
                            anchors.centerIn: parent
                            implicitSize: 20
                            source: toast.model.icon !== "" ? Quickshell.iconPath(toast.model.icon, true) : ""
                            visible: status === Image.Ready
                        }
                        Icon {
                            anchors.centerIn: parent
                            visible: !appIcon.visible
                            name: "bell"
                            size: 17
                            color: Theme.accent
                        }
                    }

                    ColumnLayout {
                        spacing: 2
                        Layout.fillWidth: true

                        RowLayout {
                            Text { text: toast.model.app; color: Theme.subtext; font { family: Theme.font; pixelSize: 10; bold: true } }
                            Item { Layout.fillWidth: true }
                            Text { text: "now"; color: Theme.overlay; font { family: Theme.font; pixelSize: 10 } }
                        }
                        Text {
                            text: toast.model.title
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 13; bold: true }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                        Text {
                            visible: text !== ""
                            text: toast.model.body
                            textFormat: Text.PlainText
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: 12 }
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }

                    BarButton {
                        implicitWidth: 22
                        implicitHeight: 22
                        icon: "x"
                        iconSize: 13
                        iconColor: Theme.overlay
                        Layout.alignment: Qt.AlignTop
                        onClicked: root.close(toast.model.tid)
                    }
                }
            }
        }
    }
}
