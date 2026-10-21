import QtQuick
import QtQuick.Layouts
import "../components"
import "../services"

// Idle: when to blank the screens and when to lock, plus Caffeine, which
// pauses both (and any idle daemon that respects idle inhibitors).
ColumnLayout {
    id: root

    property bool showBack: false
    property bool active: false
    signal back()

    spacing: 6

    readonly property var blankChoices: [0, 2, 5, 10, 15, 30].map(m => ({ value: m, label: m ? m + " min" : "Never" }))
    readonly property var lockChoices: [0, 5, 10, 15, 30, 60].map(m => ({ value: m, label: m ? m + " min" : "Never" }))
    readonly property bool usable: Idle.configured || SystemInfo.idleDaemon

    PageHeader {
        icon: "coffee"
        title: "Idle"
        showBack: root.showBack
        onBack: root.back()
    }

    SettingRow {
        label: "Blank screens after"
        OptionPicker {
            implicitWidth: 120
            options: root.blankChoices
            selectedValue: Idle.blank
            onPicked: v => Idle.set("blank", v)
        }
    }
    SettingRow {
        label: "Lock after"
        OptionPicker {
            implicitWidth: 120
            options: root.lockChoices
            selectedValue: Idle.lock
            onPicked: v => Idle.set("lock", v)
        }
    }

    SectionLabel { text: "Caffeine" }
    SettingRow {
        label: !root.usable ? "Set a timer above first" : Shell.caffeine ? "Staying awake" : "Keep the screens awake"
        opacity: root.usable ? 1 : 0.5
        Switch {
            checked: Shell.caffeine && root.usable
            onToggled: if (root.usable) Shell.caffeine = !Shell.caffeine
        }
    }
    Text {
        visible: SystemInfo.idleDaemon
        text: "An idle daemon is running too; Caffeine also pauses it if it respects idle inhibitors."
        color: Theme.overlay
        wrapMode: Text.WordWrap
        font { family: Theme.font; pixelSize: 10 }
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.topMargin: 2
    }

    component SettingRow: RowLayout {
        property string label: ""
        default property alias control: holder.data
        spacing: 10
        Layout.fillWidth: true
        Layout.leftMargin: 4
        Layout.topMargin: 2
        Text {
            text: parent.label
            color: Theme.subtext
            font { family: Theme.font; pixelSize: 11 }
            Layout.fillWidth: true
        }
        Item {
            id: holder
            implicitWidth: childrenRect.width
            implicitHeight: childrenRect.height
        }
    }
}
