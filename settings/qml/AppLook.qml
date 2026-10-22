import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

ColumnLayout {
    id: root
    width: parent ? parent.width : 800
    spacing: 16 * Theme.density
    ColorDialog {
        id: picker
        property string key
        onAccepted: Store.setValue("settings", key, selectedColor.toString())
    }
    SettingGroup {
        Layout.leftMargin: 22 * Theme.density
        Layout.rightMargin: 22 * Theme.density
        title: "background"
        configSection: "settings.background"
        GridLayout {
            Layout.fillWidth: true
            columns: width >= 600 ? 4 : 2
            columnSpacing: 8
            rowSpacing: 8
            Repeater {
                model: [
                    {id: "theme", label: "theme gradient", hint: "water from your palette"},
                    {id: "solid", label: "solid", hint: "a quiet, flat surface"},
                    {id: "custom", label: "custom gradient", hint: "your own top and bottom"},
                    {id: "wallpaper", label: "wallpaper", hint: "blurred image wallpaper"}
                ]
                ArchiveButton {
                    id: card
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    checkable: true
                    autoExclusive: true
                    checked: Theme.setting("backgroundStyle", "theme") === modelData.id
                    Accessible.name: modelData.label
                    Accessible.description: modelData.hint
                    onClicked: Store.setValue("settings", "backgroundStyle", modelData.id)
                    contentItem: ColumnLayout {
                        spacing: 6
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: Theme.radius
                            gradient: Gradient {
                                GradientStop { position: 0; color: card.modelData.id === "solid" ? Theme.base : card.modelData.id === "custom" ? Theme.setting("backgroundTop", Theme.backdropTop) : Theme.backdropTop }
                                GradientStop { position: 1; color: card.modelData.id === "solid" ? Theme.base : card.modelData.id === "custom" ? Theme.setting("backgroundBottom", Theme.crust) : Theme.crust }
                            }
                            Rectangle { x: parent.width * 0.18; y: 10; width: parent.width * 0.64; height: 14; radius: 3; color: Theme.glass; border.color: Theme.edge }
                        }
                        Label { text: card.modelData.label; color: card.checked ? Theme.glow : Theme.text; font.pixelSize: 10; Layout.fillWidth: true; elide: Text.ElideRight }
                        Label { text: card.modelData.hint; color: Theme.subtext; font.pixelSize: 9; Layout.fillWidth: true; elide: Text.ElideRight }
                    }
                    Keys.onRightPressed: nextItemInFocusChain().forceActiveFocus()
                    Keys.onLeftPressed: nextItemInFocusChain(false).forceActiveFocus()
                }
            }
        }
        RowLayout {
            visible: Theme.setting("backgroundStyle", "theme") === "custom"
            Layout.fillWidth: true
            Layout.topMargin: 12
            Repeater {
                model: [{key: "backgroundTop", label: "top", fallback: Theme.backdropTop}, {key: "backgroundBottom", label: "bottom", fallback: Theme.crust}]
                ArchiveButton {
                    required property var modelData
                    text: modelData.label + " · " + Theme.setting(modelData.key, modelData.fallback)
                    Layout.fillWidth: true
                    onClicked: { picker.key = modelData.key; picker.selectedColor = Theme.setting(modelData.key, modelData.fallback); picker.open(); }
                }
            }
            ArchiveButton { text: "from theme"; onClicked: { Store.setValue("settings", "backgroundTop", Theme.backdropTop.toString()); Store.setValue("settings", "backgroundBottom", Theme.crust.toString()); } }
        }
        Label {
            visible: Theme.setting("backgroundStyle", "theme") === "wallpaper"
            text: "Uses an image wallpaper from the first detected output. Video wallpapers use the theme gradient."
            color: Theme.subtext
            font.pixelSize: 10
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.topMargin: 8
        }
        Field {
            title: "window opacity"
            hint: "Lets your desktop show through the water."
            kind: "slider"; minimum: 40; maximum: 100; unit: "%"
            value: Theme.setting("windowOpacity", 100)
            onEdited: next => Store.setValue("settings", "windowOpacity", next)
        }
    }
    GridLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 22 * Theme.density
        Layout.rightMargin: 22 * Theme.density
        columns: root.width >= 900 ? 2 : 1
        columnSpacing: 16
        rowSpacing: 16
        JsonForm {
            Layout.alignment: Qt.AlignTop
            title: "atmosphere"
            configSection: "settings.atmosphere"
            documentId: "settings"
            fields: [
                {title: "light shafts", hint: "Soft light through the water above.", key: "shafts", kind: "slider", fallback: 100, unit: "%"},
                {title: "marine snow", hint: "A slow drift of tiny suspended particles.", key: "snow", kind: "slider", fallback: 80, unit: "%"},
                {title: "drift", hint: "Pause the water when you need stillness.", key: "drift", kind: "bool", fallback: true},
                {title: "reduce motion", hint: "Static atmosphere and short fades.", key: "reduceMotion", kind: "bool", fallback: false}
            ]
        }
        JsonForm {
            Layout.alignment: Qt.AlignTop
            title: "surfaces & glow"
            configSection: "settings.surfaces"
            documentId: "settings"
            fields: [
                {title: "glass", key: "glass", kind: "slider", fallback: 3, max: 15, unit: "%"},
                {title: "glow strength", key: "glowStrength", kind: "slider", fallback: 15, max: 40, unit: "%"},
                {title: "glow colour", key: "glowSource", kind: "choice", fallback: "cyan", choices: ["cyan", "accent", "rose"].map(v => ({value: v, label: v}))},
                {title: "selected page", key: "selectionStyle", kind: "choice", fallback: "edge", choices: [{value: "edge", label: "lit edge"}, {value: "filled", label: "filled"}, {value: "underline", label: "underline"}]}
            ]
        }
        JsonForm {
            Layout.alignment: Qt.AlignTop
            title: "layout & text"
            configSection: "settings.layout"
            documentId: "settings"
            fields: [
                {title: "density", key: "density", kind: "choice", fallback: "normal", choices: ["compact", "normal", "roomy"].map(v => ({value: v, label: v}))},
                {title: "font", hint: "Installed fonts only; monospace is the fallback.", key: "font", kind: "choice", fallback: "JetBrains Mono", choices: Theme.fonts.map(v => ({value: v, label: v}))},
                {title: "group corners", hint: "Carved brackets around each group.", key: "corners", kind: "bool", fallback: true}
            ]
        }
    }
    RowLayout {
        Layout.leftMargin: 22 * Theme.density
        Layout.rightMargin: 22 * Theme.density
        Layout.fillWidth: true
        ArchiveButton { text: "reset to theme"; onClicked: Store.resetAppLook() }
        ArchiveButton {
            text: "save look into theme"
            enabled: Theme.theme.readOnly === false
            ToolTip.visible: hovered
            ToolTip.text: enabled ? "Stores this look in your custom theme draft." : "Create an editable theme copy in Colours & theme."
            onClicked: Store.setValue("theme:" + Theme.themeId, "settingsLook", JSON.parse(Store.text("settings")))
        }
        Item { Layout.fillWidth: true }
        Label { text: "^, this app · ^F search"; color: Theme.subtext; font.pixelSize: 10 }
    }
    Item { Layout.preferredHeight: 16 }
}
