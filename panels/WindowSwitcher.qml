import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import "../components"
import "../services"

// Alt+Tab window switcher, off unless a keybind calls it:
//   bind Alt+Tab { "spawn:qs -c abyssal ipc call shell switcher" }
// Opens on the monitor you are working on with the windows most recently
// used first and the previous one picked. Each call (Tab) moves on;
// Shift+Tab / arrows go back; letting go of Alt, Enter or a click switches;
// Esc cancels.
PanelWindow {
    id: root

    required property string output
    readonly property bool open: Shell.switcherOn === output
    property bool shown: false
    property int selected: 0
    // Toplevels when it opened, most recent first.
    property var list: []

    onOpenChanged: {
        if (open) {
            list = Shell.windowsByRecent()
            selected = list.length > 1 ? 1 : 0
            shown = true
        }
    }
    Connections {
        target: Shell
        function onSwitcherStep(dir) {
            if (root.open && root.list.length) root.selected = (root.selected + dir + root.list.length) % root.list.length
        }
    }

    function choose() {
        const t = list[selected]
        Shell.switcherOn = ""
        if (t) t.activate()
    }

    WlrLayershell.namespace: "abyssal-switcher"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors { top: true; bottom: true; left: true; right: true }
    exclusiveZone: -1
    color: "transparent"
    visible: shown

    Item {
        id: stage
        anchors.fill: parent
        focus: true
        property real t: root.open ? 1 : 0
        Behavior on t { NumberAnimation { duration: root.open ? 160 : 120; easing.type: Easing.OutCubic } }
        onTChanged: if (t === 0 && !root.open) root.shown = false
        opacity: t

        Connections {
            target: root
            function onOpenChanged() { if (root.open) stage.forceActiveFocus() }
        }
        Keys.onPressed: e => {
            if (e.key === Qt.Key_Tab || e.key === Qt.Key_Right) { Shell.switcherStep(1); e.accepted = true }
            else if (e.key === Qt.Key_Backtab || e.key === Qt.Key_Left) { Shell.switcherStep(-1); e.accepted = true }
            else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter) { root.choose(); e.accepted = true }
            else if (e.key === Qt.Key_Escape) { Shell.switcherOn = ""; e.accepted = true }
        }
        Keys.onReleased: e => { if (e.key === Qt.Key_Alt || e.key === Qt.Key_Meta) root.choose() }

        MouseArea { anchors.fill: parent; onClicked: Shell.switcherOn = "" }

        Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, cards.implicitWidth + 28)
            height: cards.implicitHeight + 28
            radius: Theme.popupRadius
            color: Theme.glassStrong
            border.width: 1
            border.color: Theme.hairline
            scale: 0.96 + 0.04 * stage.t

            Text {
                visible: root.list.length === 0
                anchors.centerIn: parent
                text: "No windows"
                color: Theme.subtext
                font { family: Theme.font; pixelSize: 12 }
            }

            Row {
                id: cards
                anchors.centerIn: parent
                spacing: 8
                Repeater {
                    model: root.list
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        required property int index
                        readonly property bool current: index === root.selected
                        readonly property var entry: modelData.appId ? DesktopEntries.heuristicLookup(modelData.appId) : null
                        width: 132
                        height: 120
                        radius: Theme.controlRadius
                        color: current ? Theme.accentSoft : area.containsMouse ? Theme.hover : "transparent"
                        border.width: current ? 1 : 0
                        border.color: Theme.alpha(Theme.accent, 0.5)

                        ColumnLayout {
                            anchors { fill: parent; margins: 10 }
                            spacing: 8
                            Item {
                                Layout.alignment: Qt.AlignHCenter
                                implicitWidth: 48; implicitHeight: 48
                                AppIcon {
                                    id: icon
                                    anchors.fill: parent
                                    iconName: card.entry ? card.entry.icon : (card.modelData.appId || "")
                                    visible: status === Image.Ready
                                }
                                Icon { anchors.centerIn: parent; visible: !icon.visible; name: "app"; size: 32; color: Theme.subtext }
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: card.entry ? card.entry.name : (card.modelData.appId || "Window")
                                color: card.current ? Theme.accent : Theme.text
                                font { family: Theme.font; pixelSize: 11; bold: true }
                            }
                            Text {
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: card.modelData.title || ""
                                color: Theme.overlay
                                font { family: Theme.font; pixelSize: 9 }
                            }
                        }
                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: root.selected = card.index
                            onClicked: root.choose()
                        }
                    }
                }
            }
        }
    }
}
