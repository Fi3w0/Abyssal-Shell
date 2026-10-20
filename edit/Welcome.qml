import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// First start (no layout.json yet): pick a starting layout for every
// monitor. Everything stays editable afterwards.
PanelWindow {
    id: root

    visible: PanelLayout.firstRun
    WlrLayershell.namespace: "abyssal-welcome"
    WlrLayershell.layer: WlrLayer.Overlay
    exclusiveZone: 0
    color: "transparent"
    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card
        anchors.fill: parent
        implicitWidth: col.implicitWidth + 56
        implicitHeight: col.implicitHeight + 56
        radius: 24
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.alpha(Theme.cyan, 0.35)

        ColumnLayout {
            id: col
            anchors.centerIn: parent
            spacing: 18

            RowLayout {
                spacing: 12
                Icon { name: "logo"; size: 26; stroke: 2.2; color: Theme.cyan }
                Text {
                    text: "Welcome to Abyssal"
                    color: Theme.text
                    font { family: Theme.font; pixelSize: 22; bold: true }
                }
            }
            Text {
                text: "Pick where to start. Every panel stays editable: right-click one → Edit panels."
                color: Theme.subtext
                font { family: Theme.font; pixelSize: 12 }
            }

            RowLayout {
                spacing: 14
                Repeater {
                    model: [
                        { key: "classic", desc: "One bottom panel: launcher, open windows, tray, clock", shape: "classic" },
                        { key: "rice", desc: "Top bar plus a floating dock at the bottom", shape: "rice" },
                        { key: "topbar", desc: "Just the top bar, nothing at the bottom", shape: "topbar" }
                    ]
                    delegate: Rectangle {
                        id: option
                        required property var modelData
                        implicitWidth: 230
                        implicitHeight: 210
                        radius: 18
                        color: area.containsMouse ? Theme.alpha(Theme.surface1, 0.95) : Theme.alpha(Theme.surface0, 0.9)
                        border.width: 1
                        border.color: area.containsMouse ? Theme.alpha(Theme.accent, 0.6) : Theme.hairline

                        // Tiny screen showing the layout.
                        Rectangle {
                            id: screenShape
                            x: 16; y: 16
                            width: parent.width - 32
                            height: 110
                            radius: 10
                            color: Theme.crust
                            border.width: 1
                            border.color: Theme.hairline

                            Rectangle {
                                visible: option.modelData.shape !== "classic"
                                x: 6; y: 6; width: parent.width - 12; height: 10; radius: 5
                                color: Theme.alpha(Theme.accent, 0.55)
                            }
                            Rectangle {
                                visible: option.modelData.shape === "classic"
                                x: 0; y: parent.height - 14; width: parent.width; height: 14
                                color: Theme.alpha(Theme.accent, 0.55)
                            }
                            Rectangle {
                                visible: option.modelData.shape === "rice"
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: parent.height - 22; width: parent.width * 0.42; height: 14; radius: 7
                                color: Theme.alpha(Theme.cyan, 0.6)
                            }
                        }

                        Text {
                            x: 16
                            y: screenShape.y + screenShape.height + 14
                            text: PanelLayout.presets[option.modelData.key].name
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 13; bold: true }
                        }
                        Text {
                            x: 16
                            y: screenShape.y + screenShape.height + 34
                            width: parent.width - 32
                            wrapMode: Text.WordWrap
                            text: option.modelData.desc
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: 10 }
                        }

                        MouseArea {
                            id: area
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: PanelLayout.applyPreset("*", option.modelData.key)
                        }
                    }
                }
            }
        }
    }
}
