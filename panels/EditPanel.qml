import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// Plasma-style bar editor for one monitor, shown while Shell.editing.
// Bars: add one per free edge, move it to another edge, style, size,
// auto-hide, remove. Widgets: pick a bar and section, click to add; moving
// and removing happens on the bars themselves.
PanelWindow {
    id: root

    readonly property string output: screen ? screen.name : ""
    readonly property var bars: BarLayout.barsFor(output)
    readonly property var edgeNames: ({ top: "Top", bottom: "Bottom", left: "Left", right: "Right" })

    // Where the widget drawer adds to.
    property string targetEdge: ""
    property string targetSection: "end"
    readonly property string effectiveEdge: bars.find(b => b.edge === targetEdge) ? targetEdge : (bars.length ? bars[0].edge : "")

    WlrLayershell.namespace: "abyssal-edit"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
    color: "transparent"
    implicitWidth: 640
    implicitHeight: card.implicitHeight

    function barFor(edge) {
        return bars.find(b => b.edge === edge)
    }

    Rectangle {
        id: card
        anchors.fill: parent
        implicitHeight: col.implicitHeight + 36
        radius: 22
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.alpha(Theme.cyan, 0.35)

        Keys.onEscapePressed: Shell.setEditing(false)

        ColumnLayout {
            id: col
            anchors { fill: parent; margins: 18 }
            spacing: 14

            // ── Header ──────────────────────────────────────────────────
            RowLayout {
                spacing: 10
                Layout.fillWidth: true

                Icon { name: "layout"; size: 18; color: Theme.cyan }
                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "Edit bars"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 15; bold: true }
                    }
                    Text {
                        text: root.output + (BarLayout.hasOwnLayout(root.output) ? " · own layout" : " · shared layout")
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: 11 }
                    }
                }
                Item { Layout.fillWidth: true }
                TextButton {
                    visible: BarLayout.hasOwnLayout(root.output)
                    text: "Use shared layout"
                    onClicked: BarLayout.resetMonitor(root.output)
                }
                TextButton {
                    text: "Done"
                    icon: "check"
                    accent: true
                    onClicked: Shell.setEditing(false)
                }
            }

            Text {
                text: "Drag widgets on a bar to move them, × removes. Changes save right away to ~/.config/abyssal/layout.json."
                color: Theme.overlay
                wrapMode: Text.WordWrap
                font { family: Theme.font; pixelSize: 11 }
                Layout.fillWidth: true
            }

            // ── One row per edge ────────────────────────────────────────
            Repeater {
                model: BarLayout.edges

                delegate: Rectangle {
                    id: row
                    required property string modelData
                    readonly property var bar: root.barFor(modelData)

                    Layout.fillWidth: true
                    implicitHeight: 48
                    radius: 14
                    color: Theme.alpha(Theme.surface0, row.bar ? 0.9 : 0.4)
                    border.width: 1
                    border.color: Theme.hairline

                    RowLayout {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 8 }
                        spacing: 8

                        Text {
                            text: root.edgeNames[row.modelData]
                            color: row.bar ? Theme.text : Theme.overlay
                            font { family: Theme.font; pixelSize: 12; bold: row.bar !== undefined }
                            Layout.preferredWidth: 58
                        }

                        Item { visible: !row.bar; Layout.fillWidth: true }
                        TextButton {
                            visible: !row.bar
                            text: "Add bar"
                            icon: "plus"
                            onClicked: BarLayout.addBar(root.output, row.modelData)
                        }

                        Segmented {
                            visible: !!row.bar
                            options: [{ value: "islands", label: "Islands" }, { value: "solid", label: "Solid" }]
                            value: row.bar ? row.bar.style : ""
                            onPicked: v => BarLayout.setBar(root.output, row.modelData, "style", v)
                        }

                        Segmented {
                            visible: !!row.bar
                            options: [{ value: "always", label: "Always" }, { value: "autohide", label: "Auto-hide" }]
                            value: row.bar ? row.bar.visibility : ""
                            onPicked: v => BarLayout.setBar(root.output, row.modelData, "visibility", v)
                        }

                        // Size stepper
                        RowLayout {
                            visible: !!row.bar
                            spacing: 2
                            BarButton {
                                implicitWidth: 26; implicitHeight: 26
                                icon: "minus"; iconSize: 13
                                onClicked: BarLayout.setBar(root.output, row.modelData, "size", row.bar.size - 2)
                            }
                            Text {
                                text: row.bar ? row.bar.size : ""
                                color: Theme.text
                                horizontalAlignment: Text.AlignHCenter
                                font { family: Theme.font; pixelSize: 12; bold: true }
                                Layout.preferredWidth: 24
                            }
                            BarButton {
                                implicitWidth: 26; implicitHeight: 26
                                icon: "plus"; iconSize: 13
                                onClicked: BarLayout.setBar(root.output, row.modelData, "size", row.bar.size + 2)
                            }
                        }

                        Item { visible: !!row.bar; Layout.fillWidth: true }

                        // Move to another free edge
                        Repeater {
                            model: row.bar ? BarLayout.edges.filter(e => e !== row.modelData) : []
                            delegate: BarButton {
                                required property string modelData
                                implicitWidth: 26; implicitHeight: 26
                                enabled: !root.barFor(modelData)
                                opacity: enabled ? 1 : 0.25
                                icon: "arrow-" + (modelData === "top" ? "up" : modelData === "bottom" ? "down" : modelData)
                                iconSize: 13
                                onClicked: BarLayout.moveBar(root.output, row.modelData, modelData)
                            }
                        }

                        BarButton {
                            visible: !!row.bar
                            implicitWidth: 28; implicitHeight: 28
                            icon: "trash"; iconSize: 14
                            iconColor: Theme.danger
                            onClicked: BarLayout.removeBar(root.output, row.modelData)
                        }
                    }
                }
            }

            // ── Widget drawer ───────────────────────────────────────────
            RowLayout {
                visible: root.bars.length > 0
                spacing: 8
                Layout.fillWidth: true
                Text {
                    text: "Add widgets to"
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: 12 }
                }
                Segmented {
                    options: root.bars.map(b => ({ value: b.edge, label: root.edgeNames[b.edge] }))
                    value: root.effectiveEdge
                    onPicked: v => root.targetEdge = v
                }
                Segmented {
                    options: [{ value: "start", label: "Start" }, { value: "center", label: "Center" }, { value: "end", label: "End" }]
                    value: root.targetSection
                    onPicked: v => root.targetSection = v
                }
            }

            Flow {
                visible: root.bars.length > 0
                spacing: 6
                Layout.fillWidth: true

                Repeater {
                    model: Object.keys(Widgets.registry)
                    delegate: Rectangle {
                        id: chip
                        required property string modelData
                        readonly property var info: Widgets.registry[modelData]
                        readonly property bool usable: Widgets.available(modelData)

                        width: chipRow.implicitWidth + 20
                        height: 30
                        radius: 15
                        color: chipArea.containsMouse && usable ? Theme.accentSoft : Theme.alpha(Theme.surface1, 0.7)
                        border.width: 1
                        border.color: chipArea.containsMouse && usable ? Theme.alpha(Theme.accent, 0.6) : Theme.hairline
                        opacity: usable ? 1 : 0.4

                        Row {
                            id: chipRow
                            anchors.centerIn: parent
                            spacing: 6
                            Icon {
                                anchors.verticalCenter: parent.verticalCenter
                                name: chip.usable ? "plus" : "x"
                                size: 12
                                color: chip.usable ? Theme.accent : Theme.overlay
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: chip.info.name + (chip.usable ? "" : " · laptop only")
                                color: Theme.text
                                font { family: Theme.font; pixelSize: 11 }
                            }
                        }

                        MouseArea {
                            id: chipArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: chip.usable ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: if (chip.usable && root.effectiveEdge !== "")
                                BarLayout.addWidget(root.output, root.effectiveEdge, root.targetSection, chip.modelData)
                        }
                    }
                }
            }

            Text {
                visible: root.bars.length === 0
                text: "This monitor has no bars. Add one above."
                color: Theme.overlay
                font { family: Theme.font; pixelSize: 12 }
            }
        }
    }
}
