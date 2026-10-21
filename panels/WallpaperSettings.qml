import QtQuick
import QtQuick.Layouts
import Quickshell
import "../components"
import "../services"

ColumnLayout {
    id: root
    property bool active: false
    property string output: Shell.detail ? Shell.detail.output : ""
    readonly property var entry: (Wallpaper.config.screens || {})[output] || (Wallpaper.config.screens || {})["*"] || {}
    spacing: 12
    PageHeader {
        title: "Wallpapers"; icon: "image"; showBack: true
        onBack: Shell.toggleWallpaperPicker(root.output)
    }
    Text {
        Layout.fillWidth: true
        text: Wallpaper.useAwww ? "awww transitions for images · mpvpaper for videos"
            : "Native image fades · mpvpaper for videos" + (Wallpaper.awwwAvailable ? "" : "\nInstall awww for wave, wipe and other transitions.")
        wrapMode: Text.WordWrap
        color: Theme.subtext
        font { family: Theme.font; pixelSize: 11 }
    }
    GridLayout {
        columns: 2
        columnSpacing: 12; rowSpacing: 10
        Layout.fillWidth: true
        Text { text: "Monitor"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        OptionPicker {
            Layout.fillWidth: true
            options: Quickshell.screens.map(s => ({value: s.name, label: s.name}))
            selectedValue: root.output
            onPicked: v => root.output = v
        }
        Text { text: "Image renderer"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        OptionPicker {
            Layout.fillWidth: true
            options: [{value: "auto", label: "Automatic (awww when installed)"}, {value: "native", label: "Native image renderer"}]
            selectedValue: Wallpaper.config.imageBackend || "auto"
            onPicked: v => Wallpaper.setOption("imageBackend", v)
        }
        Text { text: "Scale"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        OptionPicker {
            Layout.fillWidth: true
            options: [{value: "crop", label: "Fill screen"}, {value: "fit", label: "Fit whole image"}]
            selectedValue: root.entry.fit || "crop"
            onPicked: v => Wallpaper.setFit(root.output, v)
        }
        Text { text: "Transition"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        OptionPicker {
            Layout.fillWidth: true
            options: [{value: "none", label: "None"}, {value: "fade", label: "Fade"}].concat(Wallpaper.useAwww
                ? ["wave", "wipe", "grow", "center", "outer", "left", "right", "top", "bottom", "random"].map(v => ({value: v, label: v.charAt(0).toUpperCase() + v.slice(1)})) : [])
            selectedValue: Wallpaper.transition
            onPicked: v => {Wallpaper.setOption("transitionPreset", ""); Wallpaper.setOption("transition", v)}
        }
        Text { text: "Preset"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        OptionPicker {
            Layout.fillWidth: true
            options: [{value: "", label: "Custom"}].concat(Object.keys(Wallpaper.transitionPresets).map(id => ({value: id, label: Wallpaper.transitionPresets[id].name})))
            selectedValue: Wallpaper.config.transitionPreset || ""
            onPicked: v => {if(v)Wallpaper.selectPreset(v);else Wallpaper.setOption("transitionPreset", "")}
        }
        Text { text: "Duration"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        RowLayout {
            Layout.fillWidth: true
            enabled: Wallpaper.transition !== "none"
            Slider {
                Layout.fillWidth: true; Layout.minimumWidth: 60
                value: Wallpaper.transitionDuration / 3
                onMoved: v => Wallpaper.setOption("transitionDuration", Math.round(v * 3000) / 1000)
            }
            NumberInput {
                Layout.preferredWidth: 106
                value: Math.round(Wallpaper.transitionDuration * 1000)
                minimum: 0; maximum: 3000; suffix: "ms"; label: "Wallpaper transition duration"
                onCommitted: v => Wallpaper.setOption("transitionDuration", v / 1000)
            }
        }
    }
    Text {
        Layout.fillWidth: true
        text: "Scale applies to the selected monitor. Transition presets apply to images and videos on all monitors."
        wrapMode: Text.WordWrap
        color: Theme.overlay
        font { family: Theme.font; pixelSize: 10 }
    }
}
