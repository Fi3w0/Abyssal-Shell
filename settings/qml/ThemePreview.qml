import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root
    implicitHeight: 250
    radius: Theme.groupRadius
    border.color: Theme.edge
    gradient: Gradient { GradientStop { position: 0; color: Theme.backdropTop } GradientStop { position: 1; color: Theme.crust } }
    readonly property real panelOpacity: { Theme.revision; return Store.value("theme:"+Theme.themeId, "glass", .72); }
    readonly property real popupOpacity: { Theme.revision; return Store.value("theme:"+Theme.themeId, "glassStrong", .88); }
    readonly property real popupRadius: { Theme.revision; return Store.value("theme:"+Theme.themeId, "radius.popup", 22); }
    readonly property real controlRadius: { Theme.revision; return Store.value("theme:"+Theme.themeId, "radius.control", 16); }
    Rectangle {
        x: 12; y: 12; width: parent.width - 24; height: 26
        radius: Theme.square ? 3 : 13
        color: Theme.alpha(Theme.base, root.panelOpacity); border.color: Theme.edge
        Row { anchors.left: parent.left; anchors.leftMargin: 10; anchors.verticalCenter: parent.verticalCenter; spacing: 5; Repeater { model: 3; Rectangle { required property int index; width: index === 0 ? 18 : 5; height: 5; radius: 3; color: index === 0 ? Theme.accent : Theme.overlay } } }
        Label { anchors.centerIn: parent; text: "21:47"; font.pixelSize: 10; color: Theme.text }
        Label { anchors.right: parent.right; anchors.rightMargin: 10; anchors.verticalCenter: parent.verticalCenter; text: "wi-fi · 78%"; font.pixelSize: 9; color: Theme.subtext }
    }
    Rectangle {
        x: 16; y: 52; width: parent.width * .57; height: 154
        radius: Theme.square ? 3 : 8; color: Theme.base; border.color: Theme.accent
        Column {
            anchors.fill: parent; anchors.margins: 12; spacing: 7
            Label { text: "terminal · ~/abyssal"; color: Theme.subtext; font.pixelSize: 9 }
            Rectangle { width: parent.width; height: 1; color: Theme.edge }
            Label { text: "~ › git status"; color: Theme.cyan; font.pixelSize: 10 }
            Label { text: "on branch main"; color: Theme.text; font.pixelSize: 10 }
            Label { text: "modified: my-theme.json"; color: Theme.warn; font.pixelSize: 9 }
            Label { text: "✓ changes ready"; color: Theme.success; font.pixelSize: 9 }
            Row { spacing: 5; Repeater { model: [Theme.accent, Theme.cyan, Theme.rose, Theme.warn, Theme.danger, Theme.success]; Rectangle { required property color modelData; width: 12; height: 8; radius: 2; color: modelData } } }
        }
    }
    Rectangle {
        x: parent.width * .50; y: 68; width: parent.width * .46 - 12; height: 86
        radius: Math.min(14, root.popupRadius); color: Theme.alpha(Theme.surface0, root.popupOpacity); border.color: Theme.edge
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 10; spacing: 5
            Label { text: "Update ready"; color: Theme.text; font.pixelSize: 10 }
            Label { text: "12 packages · 84 MB"; color: Theme.subtext; font.pixelSize: 9 }
            Row {
                spacing: 5
                Rectangle { width: 48; height: 20; radius: Math.min(8,root.controlRadius); color: Theme.accent; Label { anchors.centerIn: parent; text: "Install"; color: Theme.crust; font.pixelSize: 9 } }
                Rectangle { width: 42; height: 20; radius: Math.min(8,root.controlRadius); color: Theme.surface1; Label { anchors.centerIn: parent; text: "Later"; color: Theme.text; font.pixelSize: 9 } }
            }
        }
    }
    Rectangle {
        x: parent.width * .56; y: 166; width: parent.width * .40 - 12; height: 40
        radius: Math.min(12,root.popupRadius); color: Theme.alpha(Theme.surface0, root.popupOpacity); border.color: Theme.edge
        Label { x: 9; y: 7; text: "volume"; color: Theme.text; font.pixelSize: 9 }
        Rectangle { x: 9; y: 26; width: parent.width-18; height: 3; radius: 2; color: Theme.overlay; Rectangle { width: parent.width*.64; height: 3; radius: 2; color: Theme.accent } }
    }
    Label { x: 12; anchors.bottom: parent.bottom; anchors.bottomMargin: 10; text: "LIVE PREVIEW · your palette, opacity & shape"; color: Theme.subtext; font.pixelSize: 9 }
}
