import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// Full-screen power menu on one monitor. Keys: L E S R P, Esc closes.
PanelWindow {
    id: root

    WlrLayershell.namespace: "abyssal-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    // Lock runs Abyssal's own lock screen (lock/shell.qml) through Shell.
    readonly property var actions: [
        { key: "L", label: "Lock",     icon: "lock",   color: Theme.cyan,    cmd: [], ready: true },
        { key: "E", label: "Logout",   icon: "logout", color: Theme.accent,  cmd: ["tidectl", "quit"], ready: true },
        { key: "S", label: "Sleep",    icon: "sleep",  color: Theme.success, cmd: ["systemctl", "suspend"], ready: true },
        { key: "R", label: "Reboot",   icon: "reboot", color: Theme.warn,    cmd: ["systemctl", "reboot"], ready: true },
        { key: "P", label: "Shutdown", icon: "power",  color: Theme.danger,  cmd: ["systemctl", "poweroff"], ready: true }
    ]

    function run(a) {
        if (!a.ready) return
        Shell.powerOn = ""
        if (a.key === "L") Shell.lock()
        else Quickshell.execDetached(a.cmd)
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.alpha(Theme.crust, 0.7)
        NumberAnimation on opacity { from: 0; to: 1; duration: 180; running: true; easing.type: Easing.OutCubic }

        MouseArea { anchors.fill: parent; onClicked: Shell.powerOn = "" }

        RowLayout {
            anchors.centerIn: parent
            spacing: 18

            Repeater {
                model: root.actions

                delegate: Item {
                    id: btn
                    required property var modelData
                    property bool hov: false

                    implicitWidth: 128
                    implicitHeight: 138
                    opacity: modelData.ready ? 1 : 0.45

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.popupRadius
                        color: Theme.glassStrong
                        border.width: 1
                        border.color: btn.hov && btn.modelData.ready ? btn.modelData.color : Theme.hairline
                        y: btn.hov && btn.modelData.ready ? -6 : 0
                        Behavior on y { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        Behavior on border.color { ColorAnimation { duration: 140 } }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 24
                            width: 58
                            height: 58
                            radius: 18
                            color: Theme.alpha(Theme.crust, 0.4)
                            Icon {
                                anchors.centerIn: parent
                                name: btn.modelData.icon
                                size: 26
                                color: btn.modelData.color
                            }
                        }

                        Text {
                            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 20 }
                            text: btn.modelData.ready ? btn.modelData.label : btn.modelData.label + " · soon"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 13; bold: true }
                        }

                        Rectangle {
                            anchors { top: parent.top; right: parent.right; margins: 10 }
                            width: 20
                            height: 18
                            radius: 6
                            color: Theme.surface0
                            border.width: 1
                            border.color: Theme.alpha(Theme.text, 0.07)
                            Text {
                                anchors.centerIn: parent
                                text: btn.modelData.key
                                color: Theme.subtext
                                font { family: Theme.font; pixelSize: 10 }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: btn.modelData.ready ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onEntered: btn.hov = true
                        onExited: btn.hov = false
                        onClicked: root.run(btn.modelData)
                    }
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: true
        Component.onCompleted: forceActiveFocus()
        Keys.onPressed: ev => {
            if (ev.key === Qt.Key_Escape) { Shell.powerOn = ""; return }
            const a = root.actions.find(x => x.key === ev.text.toUpperCase())
            if (a) root.run(a)
        }
    }
}
