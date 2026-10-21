import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// "Add widgets": search and categories, click a widget to add it to the
// end of the selected panel, then drag it into place on the panel. Sits on
// the side of the screen away from a left panel.
PanelWindow {
    id: root

    // Passed in, not read from `screen`: deriving visibility from the
    // window's own screen loops.
    required property string output
    readonly property var target: Shell.editTarget
    property string category: "all"
    property string query: ""

    readonly property var shownIds: Object.keys(Widgets.registry).filter(id => {
        const w = Widgets.registry[id]
        if (category !== "all" && w.cat !== category) return false
        const q = query.trim().toLowerCase()
        return q === "" || w.name.toLowerCase().includes(q) || w.desc.toLowerCase().includes(q)
    })

    readonly property bool open: Shell.editing && Shell.sidebarOpen && target !== null && target.output === output
    // Up until the slide-out is done.
    property bool shown: false
    onOpenChanged: if (open) shown = true
    visible: shown
    WlrLayershell.namespace: "abyssal-edit-sidebar"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors { top: true; bottom: true; left: true }
    margins { top: 10; bottom: 10; left: 10; right: 10 }
    exclusiveZone: 0
    implicitWidth: 330
    color: "transparent"

    Rectangle {
        id: sidebarCard
        anchors.fill: parent
        // Slides in from the left edge and fades; closing reverses it.
        property real t: root.open ? 1 : 0
        Behavior on t { NumberAnimation { duration: root.open ? 240 : 160; easing.type: Easing.OutCubic } }
        onTChanged: if (t === 0 && !root.open) root.shown = false
        opacity: t
        transform: Translate { x: -(1 - sidebarCard.t) * 28 }
        radius: 20
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.hairline

        ColumnLayout {
            anchors { fill: parent; margins: 18 }
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "Add widgets"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 15; bold: true }
                }
                Item { Layout.fillWidth: true }
                BarButton { icon: "x"; iconSize: 14; onClicked: Shell.sidebarOpen = false }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 38
                radius: height / 2
                color: Theme.alpha(Theme.crust, 0.7)
                border.width: 1
                border.color: search.activeFocus ? Theme.alpha(Theme.accent, 0.6) : Theme.hairline

                Row {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    spacing: 10
                    Icon { anchors.verticalCenter: parent.verticalCenter; name: "search"; size: 14; color: Theme.subtext }
                    TextInput {
                        id: search
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 12 }
                        clip: true
                        onTextChanged: root.query = text
                        Keys.onEscapePressed: text === "" ? (Shell.sidebarOpen = false) : (text = "")
                        Text {
                            visible: search.text === ""
                            text: "Search widgets"
                            color: Theme.overlay
                            font: search.font
                        }
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: Widgets.categories
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool on: root.category === modelData[0]
                        width: catLabel.implicitWidth + 22
                        height: 28
                        radius: 14
                        color: on ? Theme.accentSoft : "transparent"
                        border.width: 1
                        border.color: on ? Theme.alpha(Theme.accent, 0.5) : Theme.hairline
                        Text {
                            id: catLabel
                            anchors.centerIn: parent
                            text: modelData[1]
                            color: parent.on ? Theme.accent : Theme.subtext
                            font { family: Theme.font; pixelSize: 11; bold: parent.on }
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.category = modelData[0]
                        }
                    }
                }
            }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: root.shownIds
                delegate: Rectangle {
                    id: card
                    required property string modelData
                    readonly property var info: Widgets.registry[modelData]
                    readonly property bool usable: Widgets.available(modelData)

                    width: ListView.view.width
                    height: 58
                    radius: 14
                    color: area.containsMouse && usable ? Theme.alpha(Theme.surface1, 0.95) : Theme.alpha(Theme.surface0, 0.9)
                    border.width: 1
                    border.color: modelData === "spacer" ? Theme.alpha(Theme.rose, 0.45) : Theme.hairline
                    opacity: usable ? 1 : 0.45

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 12
                        Rectangle {
                            implicitWidth: 34
                            implicitHeight: 34
                            radius: 11
                            color: Theme.alpha(Theme.crust, 0.55)
                            Icon {
                                anchors.centerIn: parent
                                name: card.info.icon || "app"
                                size: 19
                                stroke: 1.8
                                color: card.usable ? Theme.accent : Theme.overlay
                            }
                        }
                        ColumnLayout {
                            spacing: 1
                            Layout.fillWidth: true
                            Text {
                                text: card.info.name
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 12; bold: true }
                            }
                            Text {
                                text: card.usable ? card.info.desc : "Laptop only, not on this machine"
                                color: Theme.subtext
                                elide: Text.ElideRight
                                font { family: Theme.font; pixelSize: 10 }
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        id: area
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: card.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: if (card.usable && root.target) Shell.addWidget(card.modelData)
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
                text: "Click to add to the selected panel, then drag it into place on the panel. Any widget works on any panel."
                color: Theme.subtext
                font { family: Theme.font; pixelSize: 11 }
            }
        }
    }
}
