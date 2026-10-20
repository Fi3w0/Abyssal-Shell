import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"

// Settings for the selected panel, popping out of its inner edge like
// Plasma's Panel Settings. Every change saves at once.
PopupWindow {
    id: root

    required property var panelWindow
    required property var config
    required property string output

    readonly property string edge: config.edge
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property var names: ({ top: "Top", bottom: "Bottom", left: "Left", right: "Right" })
    readonly property var otherScreens: Quickshell.screens.map(s => s.name).filter(n => n !== output)

    function set(key, value) {
        PanelLayout.setPanel(output, edge, key, value)
    }

    anchor.window: panelWindow
    anchor.rect.x: edge === "left" ? panelWindow.width : edge === "right" ? 0 : panelWindow.width / 2
    anchor.rect.y: edge === "top" ? panelWindow.height : edge === "bottom" ? 0 : panelWindow.height / 2
    anchor.rect.width: 1
    anchor.rect.height: 1
    anchor.gravity: edge === "top" ? Edges.Bottom : edge === "bottom" ? Edges.Top : edge === "left" ? Edges.Right : Edges.Left
    anchor.margins.top: 8
    anchor.margins.bottom: 8
    anchor.margins.left: 8
    anchor.margins.right: 8
    color: "transparent"
    implicitWidth: 600
    implicitHeight: card.implicitHeight

    Rectangle {
        id: card
        anchors.fill: parent
        implicitHeight: col.implicitHeight + 36
        radius: 20
        color: Theme.glassStrong
        border.width: 1
        border.color: Theme.alpha(Theme.cyan, 0.35)

        ColumnLayout {
            id: col
            anchors { fill: parent; margins: 18 }
            spacing: 14

            RowLayout {
                spacing: 10
                Layout.fillWidth: true
                ColumnLayout {
                    spacing: 1
                    Text {
                        text: root.names[root.edge] + " panel"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 15; bold: true }
                    }
                    Text {
                        text: root.output + (PanelLayout.hasOwnLayout(root.output) ? " · own layout" : " · shared layout")
                        color: Theme.subtext
                        font { family: Theme.font; pixelSize: 11 }
                    }
                }
                Item { Layout.fillWidth: true }
                TextButton { text: "Done"; icon: "check"; accent: true; onClicked: Shell.setEditing(false) }
            }

            GridLayout {
                columns: 2
                columnSpacing: 14
                rowSpacing: 10
                Layout.fillWidth: true

                Label { text: "Position" }
                RowLayout {
                    spacing: 8
                    TextButton { text: "Set position…"; icon: "layout"; onClicked: Shell.pickingPosition = true }
                    Repeater {
                        model: root.otherScreens
                        delegate: TextButton {
                            required property string modelData
                            text: "Move to " + modelData
                            enabled: PanelLayout.freeEdges(modelData).length > 0
                            onClicked: {
                                const free = PanelLayout.freeEdges(modelData)
                                Shell.moveTargetTo(modelData, free.includes(root.edge) ? root.edge : free[0])
                            }
                        }
                    }
                }

                Label { text: "Width" }
                Segmented {
                    options: [{ value: "fill", label: "Fill" }, { value: "fit", label: "Fit" },
                              { value: "islands", label: "Islands" }, { value: "custom", label: "Custom" }]
                    value: root.config.width
                    onPicked: v => root.set("width", v)
                }

                Label { text: "Alignment" }
                Segmented {
                    readonly property bool usable: root.config.width === "fit" || root.config.width === "custom"
                                                   || !root.config.items.some(i => i.id === "spacer")
                    options: (root.vertical ? [["start", "Top"], ["center", "Center"], ["end", "Bottom"]]
                                            : [["start", "Left"], ["center", "Center"], ["end", "Right"]])
                             .map(o => ({ value: o[0], label: o[1], enabled: usable }))
                    value: root.config.align
                    onPicked: v => root.set("align", v)
                }

                Label { text: "Length"; visible: root.config.width === "custom" }
                RowLayout {
                    visible: root.config.width === "custom"
                    spacing: 12
                    Slider {
                        Layout.preferredWidth: 300
                        value: (root.config.length - 10) / 90
                        onMoved: v => root.set("length", Math.round(10 + v * 90))
                    }
                    Text {
                        text: root.config.length + "%"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 12; bold: true }
                    }
                }

                Label { text: "Visibility" }
                Segmented {
                    options: [{ value: "always", label: "Always" }, { value: "autohide", label: "Auto-hide" },
                              { value: "below", label: "Windows below" }]
                    value: root.config.visibility
                    onPicked: v => root.set("visibility", v)
                }

                Label { text: "Look" }
                RowLayout {
                    spacing: 12
                    Segmented {
                        options: [{ value: "glass", label: "Glass" }, { value: "solid", label: "Solid" }]
                        value: root.config.look
                        onPicked: v => root.set("look", v)
                    }
                    Segmented {
                        options: [{ value: "floating", label: "Floating" }, { value: "flush", label: "Flush" }]
                        value: root.config.floating ? "floating" : "flush"
                        onPicked: v => root.set("floating", v === "floating")
                    }
                }

                Label { text: root.vertical ? "Width px" : "Height" }
                RowLayout {
                    spacing: 12
                    Slider {
                        Layout.preferredWidth: 300
                        value: (root.config.size - PanelLayout.minSize) / (PanelLayout.maxSize - PanelLayout.minSize)
                        onMoved: v => root.set("size", Math.round(PanelLayout.minSize + v * (PanelLayout.maxSize - PanelLayout.minSize)))
                    }
                    Text {
                        text: root.config.size + " px"
                        color: Theme.text
                        font { family: Theme.font; pixelSize: 12; bold: true }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.hairline }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true
                TextButton { text: "Add widgets"; icon: "plus"; onClicked: Shell.sidebarOpen = true }
                TextButton { text: "Spacer"; icon: "plus"; onClicked: PanelLayout.addItem(root.output, root.edge, "spacer") }
                Item { Layout.fillWidth: true }
                Repeater {
                    model: root.otherScreens
                    delegate: TextButton {
                        required property string modelData
                        text: "Clone to " + modelData
                        enabled: PanelLayout.freeEdges(modelData).length > 0
                        onClicked: PanelLayout.clonePanel(root.output, root.edge, modelData)
                    }
                }
                TextButton { text: "Delete"; icon: "trash"; danger: true; onClicked: Shell.removeTarget() }
            }
        }
    }

    component Label: Text {
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 12 }
        Layout.preferredWidth: 90
    }
}
