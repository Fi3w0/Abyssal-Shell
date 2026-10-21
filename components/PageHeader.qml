import QtQuick
import QtQuick.Layouts
import "../services"

// Title row of a detail page: a back button inside the quick menu (or the
// page icon in a bar popup), the title, and an optional on/off switch.
RowLayout {
    id: root

    property string icon: "square"
    property string title: ""
    property bool showBack: false
    property bool hasSwitch: false
    property bool checked: false
    signal back()
    signal toggled()

    spacing: 10
    Layout.fillWidth: true
    Layout.bottomMargin: 4

    BarButton {
        visible: root.showBack
        implicitWidth: 28
        implicitHeight: 28
        icon: "chevron-left"
        iconSize: 14
        onClicked: root.back()
    }
    Icon {
        visible: !root.showBack
        name: root.icon
        size: 16
        stroke: 1.7
        color: Theme.subtext
    }
    Text {
        text: root.title
        color: Theme.text
        font { family: Theme.font; pixelSize: 13; weight: Font.Medium }
        Layout.fillWidth: true
    }
    Switch {
        visible: root.hasSwitch
        checked: root.checked
        onToggled: root.toggled()
    }
}
