import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../components"
import "../services"

// One focusable inspector for the panel and its last selected widget.
PanelWindow {
    id: root
    required property var panelWindow
    required property var config
    required property string output

    readonly property string edge: config.edge
    readonly property bool vertical: edge === "left" || edge === "right"
    readonly property real panelInset: config.visibility === "always" ? 0
        : vertical ? panelWindow.width : panelWindow.height
    readonly property var names: ({ top: "Top", bottom: "Bottom", left: "Left", right: "Right" })
    readonly property var otherScreens: Quickshell.screens.map(s => s.name).filter(n => n !== output)
    readonly property var moveChoices: otherScreens.filter(n => PanelLayout.freeEdges(n).length > 0)
        .map(n => ({ value: n, label: n }))
    readonly property var widgetSelection: Shell.widgetTarget && Shell.widgetTarget.output === output
        && Shell.widgetTarget.edge === edge ? Shell.widgetTarget : null
    readonly property string widgetKey: widgetSelection
        ? [widgetSelection.output, widgetSelection.edge, widgetSelection.index, widgetSelection.id].join("|") : ""
    property string inspectorMode: "panel"

    function set(key, value) { PanelLayout.setPanel(output, edge, key, value) }
    function loadWidget() {
        widgetLoader.source = ""
        if (widgetSelection)
            widgetLoader.setSource(Qt.resolvedUrl("WidgetSettings.qml"), { selection: widgetSelection, identityKey: widgetKey })
    }
    onWidgetKeyChanged: {
        inspectorMode = widgetKey ? "widget" : "panel"
        Qt.callLater(loadWidget)
    }
    Component.onCompleted: loadWidget()

    screen: panelWindow.screen
    WlrLayershell.namespace: "abyssal-panel-settings"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    anchors.top: edge === "top"
    anchors.bottom: edge === "bottom"
    anchors.left: edge === "left"
    anchors.right: edge === "right"
    margins.top: edge === "top" ? panelInset + 8 : 8
    margins.bottom: edge === "bottom" ? panelInset + 80 : 8
    margins.left: edge === "left" ? panelInset + 8 : 8
    margins.right: edge === "right" ? panelInset + 8 : 8
    exclusiveZone: 0
    color: "transparent"
    implicitWidth: Math.min(Math.max(320, screen.width - 32), Math.max(480, grid.implicitWidth + 32))
    implicitHeight: Math.min(col.implicitHeight + 32, Math.max(160, screen.height - 160))

    Rectangle {
        anchors.fill: parent
        radius: Theme.popupRadius
        color: Theme.glassStrong
        border { width: 1; color: Theme.hairline }

        Flickable {
            id: scroll
            anchors { fill: parent; margins: 16 }
            clip: true
            contentWidth: width
            contentHeight: col.implicitHeight
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: col
                width: scroll.width
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: root.names[root.edge] + " panel"
                            color: Theme.text
                            font { family: Theme.font; pixelSize: 14; bold: true }
                        }
                        Text {
                            text: root.output + (PanelLayout.hasOwnLayout(root.output) ? " · own layout" : " · shared layout")
                            color: Theme.subtext
                            font { family: Theme.font; pixelSize: 10 }
                        }
                    }
                    TextButton { text: "Done"; icon: "check"; accent: true; onClicked: Shell.setEditing(false) }
                }

                Segmented {
                    Layout.fillWidth: true
                    uniform: true
                    options: [{ value: "panel", label: "Panel" }, { value: "widget", label: "Widget", enabled: !!root.widgetSelection }]
                    value: root.inspectorMode
                    onPicked: v => root.inspectorMode = v
                }

                GridLayout {
                    id: grid
                    visible: root.inspectorMode === "panel"
                    columns: 2
                    columnSpacing: 12
                    rowSpacing: 8
                    Layout.fillWidth: true

                    Label { text: "Position" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        TextButton { text: "Position…"; icon: "layout"; onClicked: Shell.pickingPosition = true }
                        OptionPicker {
                            Layout.fillWidth: true
                            options: [{ value: "", label: "Move to…" }].concat(root.moveChoices)
                            selectedValue: ""
                            enabled: root.moveChoices.length > 0
                            onPicked: v => {
                                if (!v) return
                                const free = PanelLayout.freeEdges(v)
                                if (free.length) Shell.moveTargetTo(v, free.includes(root.edge) ? root.edge : free[0])
                            }
                        }
                    }

                    Label { text: "Theme" }
                    OptionPicker {
                        Layout.fillWidth: true
                        enabled: Appearance.writable
                        options: [{ value: "trench-violet", label: "Trench / Violet" }, { value: "abyssal-tide", label: "Abyssal Tide" }]
                        selectedValue: Appearance.preset
                        onPicked: v => Appearance.set("preset", v)
                    }

                    Label { text: "Labels" }
                    Segmented {
                        Layout.fillWidth: true
                        uniform: true
                        enabled: Appearance.writable
                        options: [{ value: "sans", label: "Sans" }, { value: "mono", label: "Mono" }]
                        value: Appearance.mono ? "mono" : "sans"
                        onPicked: v => Appearance.set("mono", v === "mono")
                    }

                    Label { text: "Layout" }
                    Segmented {
                        Layout.fillWidth: true
                        uniform: true
                        options: [{ value: "fill", label: "Fill" }, { value: "fit", label: "Fit" },
                                  { value: "islands", label: "Islands" }, { value: "custom", label: "Custom" }]
                        value: root.config.width
                        onPicked: v => root.set("width", v)
                    }

                    Label { text: "Align" }
                    Segmented {
                        Layout.fillWidth: true
                        uniform: true
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
                        Layout.fillWidth: true
                        spacing: 8
                        Slider {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 100
                            value: (root.config.length - 10) / 90
                            onMoved: v => root.set("length", Math.round(10 + v * 90))
                        }
                        NumberInput {
                            Layout.preferredWidth: 88
                            value: root.config.length; minimum: 10; maximum: 100; suffix: "%"
                            label: "Panel length in percent"
                            onCommitted: v => root.set("length", v)
                        }
                    }

                    Label { text: "Visibility" }
                    Segmented {
                        Layout.fillWidth: true
                        uniform: true
                        options: [{ value: "always", label: "Always" }, { value: "autohide", label: "Auto-hide" }, { value: "below", label: "Below" }]
                        value: root.config.visibility
                        onPicked: v => root.set("visibility", v)
                    }

                    Label { text: "Surface" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Segmented {
                            Layout.fillWidth: true
                            uniform: true
                            options: [{ value: "glass", label: "Glass" }, { value: "solid", label: "Solid" }]
                            value: root.config.look
                            onPicked: v => root.set("look", v)
                        }
                        Segmented {
                            Layout.fillWidth: true
                            uniform: true
                            options: [{ value: "floating", label: "Float" }, { value: "flush", label: "Flush" }]
                            value: root.config.floating ? "floating" : "flush"
                            onPicked: v => root.set("floating", v === "floating")
                        }
                    }

                    Label { text: root.vertical ? "Width" : "Height" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Slider {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 100
                            value: (root.config.size - PanelLayout.minSize) / (PanelLayout.maxSize - PanelLayout.minSize)
                            onMoved: v => root.set("size", Math.round(PanelLayout.minSize + v * (PanelLayout.maxSize - PanelLayout.minSize)))
                        }
                        NumberInput {
                            Layout.preferredWidth: 88
                            value: root.config.size; minimum: PanelLayout.minSize; maximum: PanelLayout.maxSize; suffix: "px"
                            label: root.vertical ? "Panel width in pixels" : "Panel height in pixels"
                            onCommitted: v => root.set("size", v)
                        }
                    }

                    Label { text: "Spacing" }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Slider {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 100
                            value: (root.config.spacing + 16) / 32
                            onMoved: v => root.set("spacing", Math.round(v * 32 - 16))
                        }
                        NumberInput {
                            Layout.preferredWidth: 88
                            value: root.config.spacing; minimum: -16; maximum: 16; suffix: "px"
                            label: "Gap between widgets in pixels"
                            onCommitted: v => root.set("spacing", v)
                        }
                    }

                    Label { text: "Copy to"; visible: root.otherScreens.length > 0 }
                    OptionPicker {
                        visible: root.otherScreens.length > 0
                        Layout.fillWidth: true
                        options: [{ value: "", label: "Choose monitor…" }].concat(root.moveChoices)
                        selectedValue: ""
                        enabled: root.moveChoices.length > 0
                        onPicked: v => {
                            if (v) PanelLayout.clonePanel(root.output, root.edge, v)
                            currentIndex = 0
                        }
                    }
                }

                Loader {
                    id: widgetLoader
                    visible: root.inspectorMode === "widget"
                    Layout.fillWidth: true
                }

                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: Theme.hairline }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    TextButton { Layout.fillWidth: true; text: "Widgets"; icon: "grid"; onClicked: Shell.sidebarOpen = true }
                    TextButton { Layout.fillWidth: true; text: "Spacer"; icon: "spacer"; onClicked: Shell.addWidget("spacer") }
                    TextButton {
                        Layout.fillWidth: true
                        text: root.inspectorMode === "widget" ? "Remove" : "Delete"
                        icon: "trash"; danger: true
                        onClicked: {
                            if (root.inspectorMode === "widget" && root.widgetSelection)
                                PanelLayout.removeItem(root.output, root.edge, root.widgetSelection.index)
                            else Shell.removeTarget()
                        }
                    }
                }
            }
        }
    }

    component Label: Text {
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 12 }
        Layout.preferredWidth: 72
    }
}
