import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Wayland
import "../components"
import "../services"

// Quick settings, opened from a bar on this monitor. Sits next to that bar
// (the right end of a horizontal bar, the top of a vertical one); bars'
// exclusive zones keep it clear of them. Click outside to close.
Scope {
    id: root

    required property var screen
    readonly property var qs: Shell.quickSettings
    readonly property bool open: qs !== null && screen && qs.output === screen.name
    readonly property string edge: open ? qs.edge : "top"

    // Full-screen click catcher under the panel.
    PanelWindow {
        screen: root.screen
        visible: root.open
        WlrLayershell.namespace: "abyssal-catcher"
        WlrLayershell.layer: WlrLayer.Top
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: Shell.quickSettings = null
        }
    }

    PanelWindow {
        id: panel
        screen: root.screen
        visible: root.open
        WlrLayershell.namespace: "abyssal-quick-settings"
        WlrLayershell.layer: WlrLayer.Overlay

        anchors.top: root.edge !== "bottom"
        anchors.bottom: root.edge === "bottom"
        anchors.left: root.edge === "left"
        anchors.right: root.edge !== "left"
        margins { top: 8; bottom: 8; left: 8; right: 8 }
        exclusiveZone: 0
        color: "transparent"
        implicitWidth: 360
        implicitHeight: card.implicitHeight

        onVisibleChanged: if (visible) SystemInfo.refreshUptime()

        Rectangle {
            id: card
            anchors.fill: parent
            implicitHeight: col.implicitHeight + 32
            radius: 22
            color: Theme.glassStrong
            border.width: 1
            border.color: Theme.hairline

            ColumnLayout {
                id: col
                anchors { fill: parent; margins: 16 }
                spacing: 12

                // ── Header: user, uptime, power ─────────────────────────
                RowLayout {
                    spacing: 10
                    Layout.fillWidth: true

                    Rectangle {
                        implicitWidth: 40
                        implicitHeight: 40
                        radius: 13
                        color: Theme.alpha(Theme.cyan, 0.15)
                        Icon { anchors.centerIn: parent; name: "logo"; size: 20; stroke: 2.2; color: Theme.cyan }
                    }
                    ColumnLayout {
                        spacing: 0
                        Layout.fillWidth: true
                        Text {
                            text: Quickshell.env("USER")
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 14; bold: true }
                        }
                        Text {
                            readonly property int mins: Math.floor(SystemInfo.uptimeSec / 60)
                            text: "up " + (mins >= 60 ? Math.floor(mins / 60) + "h " : "") + (mins % 60) + "m"
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: 11 }
                        }
                    }
                    BarButton {
                        icon: "lock"
                        iconColor: Theme.cyan
                        onClicked: Shell.lock()
                    }
                    BarButton {
                        icon: "power"
                        iconColor: Theme.danger
                        onClicked: Shell.togglePower(root.screen.name)
                    }
                }

                // ── Toggles ─────────────────────────────────────────────
                GridLayout {
                    columns: 2
                    rowSpacing: 8
                    columnSpacing: 8
                    Layout.fillWidth: true

                    ToggleTile {
                        Layout.fillWidth: true
                        icon: SystemInfo.wifiEnabled ? "wifi" : "wifi-off"
                        title: "Wi-Fi"
                        detail: !SystemInfo.wifiEnabled ? "Off"
                              : SystemInfo.netType === "wifi" ? SystemInfo.netName : "On"
                        on: SystemInfo.wifiEnabled
                        onToggled: SystemInfo.setWifi(!SystemInfo.wifiEnabled)
                    }
                    ToggleTile {
                        readonly property var adapter: Bluetooth.defaultAdapter
                        Layout.fillWidth: true
                        enabled: adapter !== null
                        icon: "bluetooth"
                        title: "Bluetooth"
                        detail: !adapter ? "No adapter" : adapter.enabled ? "On" : "Off"
                        on: adapter !== null && adapter.enabled
                        onColor: Theme.cyan
                        onToggled: adapter.enabled = !adapter.enabled
                    }
                    ToggleTile {
                        Layout.fillWidth: true
                        icon: Notifications.dnd ? "bell-off" : "bell"
                        title: "Do not disturb"
                        detail: Notifications.dnd ? "Toasts hidden" : "Off"
                        on: Notifications.dnd
                        onColor: Theme.rose
                        onToggled: Notifications.dnd = !Notifications.dnd
                    }
                    ToggleTile {
                        Layout.fillWidth: true
                        icon: "coffee"
                        title: "Caffeine"
                        detail: Shell.caffeine ? "Staying awake" : "Off"
                        on: Shell.caffeine
                        onColor: Theme.warn
                        onToggled: Shell.caffeine = !Shell.caffeine
                    }
                }

                // ── Audio ───────────────────────────────────────────────
                SliderRow {
                    icon: Audio.muted || Audio.volume === 0 ? "volume-mute" : Audio.volume < 0.5 ? "volume-low" : "volume-high"
                    value: Audio.muted ? 0 : Audio.volume
                    label: Audio.sinkName
                    onIconClicked: Audio.toggleMute()
                    onMoved: v => Audio.setVolume(v)
                }
                SliderRow {
                    visible: Audio.source !== null
                    icon: Audio.micMuted ? "mic-off" : "mic"
                    value: Audio.micMuted ? 0 : Audio.micVolume
                    fill: Theme.cyan
                    label: "Microphone"
                    onIconClicked: Audio.toggleMicMute()
                    onMoved: v => Audio.setMicVolume(v)
                }

                // ── Footer ──────────────────────────────────────────────
                RowLayout {
                    spacing: 8
                    Layout.fillWidth: true
                    TextButton {
                        text: "Edit panels"
                        icon: "pencil"
                        onClicked: Shell.setEditing(true)
                    }
                    Item { Layout.fillWidth: true }
                }
            }
        }
    }

    component SliderRow: Rectangle {
        id: sr
        property string icon: ""
        property real value: 0
        property string label: ""
        property color fill: Theme.accent
        signal moved(real value)
        signal iconClicked()

        Layout.fillWidth: true
        implicitHeight: 64
        radius: 16
        color: Theme.alpha(Theme.surface0, 0.9)
        border.width: 1
        border.color: Theme.hairline

        ColumnLayout {
            anchors { fill: parent; leftMargin: 8; rightMargin: 14; topMargin: 6; bottomMargin: 8 }
            spacing: 2

            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                BarButton {
                    implicitWidth: 30; implicitHeight: 30
                    icon: sr.icon
                    iconSize: 16
                    iconColor: Theme.text
                    onClicked: sr.iconClicked()
                }
                Slider {
                    Layout.fillWidth: true
                    value: sr.value
                    fill: sr.fill
                    onMoved: v => sr.moved(v)
                }
                Text {
                    text: Math.round(sr.value * 100)
                    color: Theme.text
                    horizontalAlignment: Text.AlignRight
                    font { family: Theme.font; pixelSize: 12; bold: true }
                    Layout.preferredWidth: 28
                }
            }
            Text {
                text: sr.label
                color: Theme.overlay
                elide: Text.ElideRight
                font { family: Theme.font; pixelSize: 10 }
                Layout.fillWidth: true
                Layout.leftMargin: 8
            }
        }
    }
}
