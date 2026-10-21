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

    required property string output

    WlrLayershell.namespace: "abyssal-toast"
    WlrLayershell.layer: WlrLayer.Overlay

    // Top-right; bars' exclusive zones push it clear of them on its own.
    anchors.top: true
    anchors.right: true
    margins.top: 10
    margins.right: 10
    exclusiveZone: 0
    implicitWidth: 340
    // Fixed size, room for maxToasts: resizing a Wayland surface every
    // animation frame stutters. Only the toasts themselves take input.
    implicitHeight: 620
    color: "transparent"
    visible: toastModel.count > 0
    mask: Region { item: col }

    ListModel { id: toastModel }

    function close(tid) {
        for (let i = 0; i < toastModel.count; i++)
            if (toastModel.get(i).tid === tid) { toastModel.setProperty(i, "closing", true); break }
    }

    Connections {
        target: Notifications
        function onToast(item) {
            const here = root.output
            const target = Tide.focusedOutput !== "" ? Tide.focusedOutput : (Quickshell.screens[0]?.name ?? "")
            if (here !== target) return
            // The same notification again while it is still up: count it on
            // that toast and restart its time instead of stacking a copy.
            for (let i = 0; i < toastModel.count; i++) {
                const t = toastModel.get(i)
                if (!t.closing && t.app === item.app && t.title === item.title && t.body === item.body) {
                    toastModel.setProperty(i, "tid", item.nid)
                    toastModel.setProperty(i, "repeats", t.repeats + 1)
                    return
                }
            }
            toastModel.append({ tid: item.nid, app: item.app, title: item.title, body: item.body, icon: item.icon, closing: false, repeats: 1 })
            while (toastModel.count > Notifications.maxToasts) toastModel.remove(0)
        }
    }

    Column {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right; topMargin: 4 }
        spacing: 8
        // Toasts below a closing one glide up instead of jumping.
        move: Transition { NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic } }

        Repeater {
            model: toastModel
            delegate: Rectangle {
                id: toast
                required property var model
                required property int index
                property bool entered: false

                width: col.width
                height: row.implicitHeight + 24
                radius: Theme.square ? Theme.popupRadius : 16
                color: Theme.glassStrong
                border.width: 1
                border.color: Theme.hairline
                opacity: model.closing ? 0 : (entered ? 1 : 0)
                x: model.closing ? width + 28 : 0

                Component.onCompleted: entered = true
                Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.InCubic } }
                Behavior on opacity { NumberAnimation { duration: toast.model.closing ? 180 : 260; easing.type: toast.model.closing ? Easing.InCubic : Easing.OutCubic } }

                // Lifetime, paused while the pointer is on the toast, restarted
                // when the same notification comes in again.
                readonly property int repeats: model.repeats
                onRepeatsChanged: life.restart()
                Timer {
                    id: life
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

                        AppIcon {
                            id: appIcon
                            anchors.centerIn: parent
                            implicitSize: 20
                            iconName: toast.model.icon
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
                            Rectangle {
                                visible: toast.model.repeats > 1
                                implicitWidth: repeatText.implicitWidth + 10
                                implicitHeight: 15
                                radius: 7.5
                                color: Theme.accentSoft
                                Text {
                                    id: repeatText
                                    anchors.centerIn: parent
                                    text: "×" + toast.model.repeats
                                    color: Theme.accent
                                    font { family: Theme.font; pixelSize: 9; bold: true }
                                }
                            }
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
