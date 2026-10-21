import QtQuick
import QtQuick.Layouts
import "../services"

ColumnLayout {
    id: root
    spacing: 10
    enabled: UpdateConfig.writable
    Component.onCompleted: UpdateConfig.refreshCapabilities()

    Text {
        Layout.fillWidth: true
        text: "Shared by all update widgets and the quick menu."
        color: Theme.subtext
        wrapMode: Text.WordWrap
        font { family: Theme.font; pixelSize: 11 }
    }
    GridLayout {
        columns: 2
        columnSpacing: 12
        rowSpacing: 10
        Layout.fillWidth: true

        Text { text: "Check every"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        RowLayout {
            Layout.fillWidth: true
            Slider {
                Layout.fillWidth: true
                Layout.minimumWidth: 70
                value: Math.log(1 + UpdateConfig.intervalMinutes) / Math.log(10081)
                onMoved: v => UpdateConfig.set("intervalMinutes", Math.round(Math.exp(v * Math.log(10081)) - 1))
            }
            NumberInput {
                Layout.preferredWidth: 100
                value: UpdateConfig.intervalMinutes
                minimum: 0; maximum: 10080; suffix: "min"; label: "Update check interval; zero means manual only"
                onCommitted: v => UpdateConfig.set("intervalMinutes", v)
            }
        }
        Text { text: "At login"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        Switch { enabled: UpdateConfig.automatic; opacity: enabled ? 1 : 0.4; checked: UpdateConfig.onStartup; onToggled: UpdateConfig.set("onStartup", !UpdateConfig.onStartup) }
        Text { text: "After installs"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        Switch { enabled: UpdateConfig.automatic; opacity: enabled ? 1 : 0.4; checked: UpdateConfig.afterTransactions; onToggled: UpdateConfig.set("afterTransactions", !UpdateConfig.afterTransactions) }
        Text { text: "Manager"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        OptionPicker {
            Layout.fillWidth: true
            options: UpdateConfig.managerChoices
            selectedValue: UpdateConfig.manager
            onPicked: v => UpdateConfig.set("manager", v)
        }
        Text { text: "Flatpak"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        Switch { checked: UpdateConfig.flatpak; onToggled: UpdateConfig.set("flatpak", !UpdateConfig.flatpak) }
        Text { visible: UpdateConfig.arch; text: "AUR packages"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        Switch { visible: UpdateConfig.arch; checked: UpdateConfig.includeAur; onToggled: UpdateConfig.set("includeAur", !UpdateConfig.includeAur) }
        Text { visible: UpdateConfig.arch && !["paru", "yay"].includes(UpdateConfig.manager); text: "AUR helper"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        OptionPicker {
            visible: UpdateConfig.arch && !["paru", "yay"].includes(UpdateConfig.manager)
            enabled: UpdateConfig.includeAur
            Layout.fillWidth: true
            options: [{ value: "auto", label: "Automatic" }, { value: "paru", label: "paru" }, { value: "yay", label: "yay" }]
            selectedValue: UpdateConfig.aurHelper
            onPicked: v => UpdateConfig.set("aurHelper", v)
        }
        Text { visible: UpdateConfig.fedora; text: "Repositories"; color: Theme.subtext; font { family: Theme.font; pixelSize: 12 } }
        OptionPicker {
            visible: UpdateConfig.fedora
            Layout.fillWidth: true
            options: [{ value: "all", label: "All enabled repositories" }, { value: "selected", label: "Select repositories…" }]
            selectedValue: UpdateConfig.dnfRepoMode
            onPicked: v => UpdateConfig.set("dnfRepoMode", v)
        }
    }
    Text {
        Layout.fillWidth: true
        text: UpdateConfig.automatic ? "Checks pause while games or package managers are busy."
            : "Manual only. Use Check for updates to refresh."
        color: Theme.overlay
        wrapMode: Text.WordWrap
        font { family: Theme.font; pixelSize: 10 }
    }
    ColumnLayout {
        visible: UpdateConfig.fedora && UpdateConfig.dnfRepoMode === "selected"
        Layout.fillWidth: true
        Text {
            Layout.fillWidth: true
            text: "Choose from your enabled repositories, including configured COPR or RPM Fusion repos."
            wrapMode: Text.WordWrap
            color: Theme.subtext
            font { family: Theme.font; pixelSize: 11 }
        }
        Repeater {
            model: UpdateConfig.detected.dnfRepos || []
            RowLayout {
                required property var modelData
                Layout.fillWidth: true
                Text { Layout.fillWidth: true; text: modelData.name; elide: Text.ElideRight; color: Theme.text; font { family: Theme.font; pixelSize: 11 } }
                Switch {
                    checked: UpdateConfig.dnfRepos.includes(modelData.id)
                    onToggled: {
                        const list = UpdateConfig.dnfRepos.slice()
                        const index = list.indexOf(modelData.id)
                        if (index >= 0) list.splice(index, 1)
                        else list.push(modelData.id)
                        UpdateConfig.set("dnfRepos", list)
                    }
                }
            }
        }
        Text {
            visible: !UpdateConfig.dnfRepos.length
            text: "Select at least one repository."
            color: Theme.warn
            font { family: Theme.font; pixelSize: 11 }
        }
    }
    Text {
        visible: UpdateConfig.error !== ""
        Layout.fillWidth: true
        text: UpdateConfig.error
        color: Theme.danger
        wrapMode: Text.WordWrap
        font { family: Theme.font; pixelSize: 11 }
    }
}
