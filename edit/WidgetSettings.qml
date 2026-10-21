import QtQuick
import QtQuick.Layouts
import QtQuick.Dialogs
import QtQuick.Controls as Controls
import "../components"
import "../services"

ColumnLayout {
    id: root
    required property var selection
    required property string identityKey
    readonly property var panel: selection ? PanelLayout.panelsFor(selection.output).find(p => p.edge === selection.edge) : null
    readonly property var item: panel && selection.index >= 0 ? panel.items[selection.index] : null
    readonly property string widgetId: item && item.id === selection.id ? item.id : ""
    readonly property var schema: Widgets.options(widgetId)
    readonly property int itemSpacing: item && item.spacing !== undefined ? Number(item.spacing) : 0
    spacing: 10

    function write(key, value) {
        const t = Shell.widgetTarget
        if (!t || !item || widgetId === "" || [t.output, t.edge, t.index, t.id].join("|") !== identityKey) return
        PanelLayout.setItemOption(t.output, t.edge, t.index, key, value)
    }

    RowLayout {
        Layout.fillWidth: true
        Icon { name: (Widgets.registry[root.widgetId] || {}).icon || "app"; size: 24; color: Theme.accent }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text { text: Widgets.name(root.widgetId); color: Theme.text; font { family: Theme.font; pixelSize: 14; bold: true } }
            Text { text: (Widgets.registry[root.widgetId] || {}).desc || ""; color: Theme.subtext; font { family: Theme.font; pixelSize: 11 } wrapMode: Text.WordWrap; Layout.fillWidth: true }
        }
    }

    Repeater {
        model: root.schema
        delegate: ColumnLayout {
            id: field
            required property var modelData
            readonly property var spec: modelData
            readonly property var currentValue: root.item && root.item[spec.key] !== undefined ? root.item[spec.key] : spec.default
            Layout.fillWidth: true
            spacing: 4
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Text {
                    text: field.spec.label
                    color: Theme.subtext
                    font { family: Theme.font; pixelSize: 12 }
                    Layout.preferredWidth: 92
                    wrapMode: Text.WordWrap
                }
                Loader {
                    Layout.fillWidth: true
                    sourceComponent: field.spec.type === "number" ? numberEditor
                        : field.spec.type === "gpu" ? gpuEditor
                        : field.spec.type === "icon" ? iconEditor : choiceEditor
                }
            }

            Component {
                id: choiceEditor
                OptionPicker {
                    options: (field.spec.values || []).map(v => ({ value: v[0], label: v[1] }))
                    selectedValue: field.currentValue
                    onPicked: v => root.write(field.spec.key, v)
                }
            }
            Component {
                id: numberEditor
                RowLayout {
                    spacing: 10
                    Slider {
                        Layout.fillWidth: true; Layout.minimumWidth: 80
                        value: (Number(field.currentValue) - field.spec.minimum) / (field.spec.maximum - field.spec.minimum)
                        onMoved: v => root.write(field.spec.key, Math.round(field.spec.minimum + v * (field.spec.maximum - field.spec.minimum)))
                    }
                    NumberInput {
                        Layout.preferredWidth: 92
                        value: Number(field.currentValue)
                        minimum: field.spec.minimum; maximum: field.spec.maximum
                        suffix: field.spec.unit || ""; label: field.spec.label
                        onCommitted: v => root.write(field.spec.key, v)
                    }
                }
            }
            Component {
                id: gpuEditor
                ColumnLayout {
                    spacing: 4
                    OptionPicker {
                        Layout.fillWidth: true
                        options: GpuStats.choices
                        selectedValue: field.currentValue
                        onPicked: v => root.write(field.spec.key, v)
                    }
                    Text {
                        Layout.fillWidth: true
                        readonly property var gpu: GpuStats.device(String(field.currentValue))
                        text: !gpu ? "Selected GPU unavailable" : gpu.suspended ? "GPU is sleeping" : gpu.name
                        color: Theme.subtext; font { family: Theme.font; pixelSize: 10 }
                        wrapMode: Text.WordWrap
                    }
                }
            }
            Component {
                id: iconEditor
                ColumnLayout {
                    RowLayout {
                        OptionPicker {
                            Layout.fillWidth: true
                            options: {
                                const list = field.spec.values.map(v => ({ value: v[0], label: v[1] }))
                                list.push({ value: "theme:", label: "Theme icon…" })
                                if (!list.some(o => o.value === field.currentValue)) list.push({ value: field.currentValue, label: "Custom image / icon" })
                                return list
                            }
                            selectedValue: field.currentValue
                            onPicked: v => root.write(field.spec.key, v)
                        }
                        TextButton { text: "Image…"; onClicked: { imageDialog.optionKey = field.spec.key; imageDialog.open() } }
                    }
                    StringInput {
                        visible: String(field.currentValue).startsWith("theme:") || String(field.currentValue).startsWith("file:")
                        Layout.fillWidth: true
                        value: String(field.currentValue)
                        label: "Custom icon source"
                        onCommitted: v => root.write(field.spec.key, v)
                    }
                }
            }
        }
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 10
        Text {
            text: "Spacing"
            color: Theme.subtext
            font { family: Theme.font; pixelSize: 12 }
            Layout.preferredWidth: 92
        }
        Slider {
            Layout.fillWidth: true
            Layout.minimumWidth: 80
            value: (root.itemSpacing + 16) / 32
            onMoved: v => root.write("spacing", Math.round(v * 32 - 16))
        }
        NumberInput {
            Layout.preferredWidth: 92
            value: root.itemSpacing; minimum: -16; maximum: 16; suffix: "px"
            label: "Gap around this widget"
            onCommitted: v => root.write("spacing", v)
        }
    }

    Text {
        Layout.fillWidth: true
        visible: root.widgetId === "battery" && !SystemInfo.hasBattery
        text: "No laptop battery detected. This widget stays hidden outside edit mode."
        color: Theme.subtext; font { family: Theme.font; pixelSize: 11 } wrapMode: Text.WordWrap
    }
    Text {
        Layout.fillWidth: true
        visible: root.widgetId === "gpu" || root.widgetId === "gpu-temp"
        text: "Unavailable readings show —. Sleeping GPUs are left asleep."
        color: Theme.subtext; font { family: Theme.font; pixelSize: 11 } wrapMode: Text.WordWrap
    }
    Loader {
        active: root.widgetId === "updates"
        Layout.fillWidth: true
        sourceComponent: Component {
            Flickable {
                implicitHeight: Math.min(options.implicitHeight, 360)
                contentWidth: width
                contentHeight: options.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                UpdateSettings { id: options; width: parent.width }
                Controls.ScrollBar.vertical: Controls.ScrollBar {}
            }
        }
    }
    FileDialog {
        id: imageDialog
        property string optionKey: "icon"
        title: "Choose widget image"
        nameFilters: ["Images (*.svg *.png *.jpg *.jpeg *.webp *.gif *.bmp *.ico)", "All files (*)"]
        onAccepted: root.write(optionKey, "file:" + decodeURIComponent(selectedFile.toString().replace(/^file:\/\//, "")))
    }
}
