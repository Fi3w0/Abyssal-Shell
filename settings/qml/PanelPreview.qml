import QtQuick
import QtQuick.Controls

Rectangle {
    id: root
    property var panels: []
    property string displayName: "Shared defaults"
    property int selectedIndex: -1
    implicitHeight: 220
    radius: Theme.groupRadius
    border.color: Theme.edge
    gradient: Gradient { GradientStop { position: 0; color: Theme.backdropTop } GradientStop { position: 1; color: Theme.crust } }
    Rectangle {
        x: parent.width*.18; y: parent.height*.23; width: parent.width*.64; height: parent.height*.5
        radius: Theme.square ? 3 : 7; color: Theme.base; border.color: Theme.edge
        Rectangle { x: 10; y: 23; width: parent.width-20; height: 1; color: Theme.edge }
        Row { x: 10; y: 10; spacing: 4; Repeater { model: 3; Rectangle { width: 4; height: 4; radius: 2; color: Theme.overlay } } }
        Label { anchors.centerIn: parent; text: "Your desktop"; color: Theme.subtext; font.pixelSize: 10 }
    }
    Repeater {
        model: root.panels
        Rectangle {
            id: bar
            required property var modelData
            required property int index
            readonly property bool vertical: modelData.edge === "left" || modelData.edge === "right"
            readonly property real inset: modelData.floating ? 10 : 1
            readonly property real thickness: Math.max(10,Math.min(30,(modelData.size || 36)*.45))
            readonly property real length: (vertical ? root.height : root.width)-2*inset
            readonly property real extent: modelData.width === "custom" ? (modelData.length || 100)/100 : modelData.width === "fit" || modelData.width === "islands" ? Math.min(.8,Math.max(.25,(modelData.items || []).length*.045)) : 1
            readonly property real offset: modelData.align === "start" ? inset : modelData.align === "end" ? (vertical?root.height:root.width) - (vertical?height:width) - inset : ((vertical?root.height:root.width)-(vertical?height:width))/2
            width: vertical ? thickness : length*extent
            height: vertical ? length*extent : thickness
            x: vertical ? (modelData.edge === "right" ? root.width-width-inset : inset) : offset
            y: vertical ? offset : modelData.edge === "bottom" ? root.height-height-inset : inset
            radius: modelData.floating ? 6 : 0
            color: modelData.width === "islands" ? "transparent" : modelData.look === "solid" ? Theme.surface0 : Theme.alpha(Theme.base,.8)
            border.color: modelData.width === "islands" ? "transparent" : index === root.selectedIndex ? Theme.glow : Theme.edge
            opacity: modelData.visibility === "autohide" ? .55 : 1
            Flow {
                anchors.fill: parent; anchors.margins: 4
                flow: bar.vertical ? Flow.TopToBottom : Flow.LeftToRight
                spacing: 3
                clip: true
                Repeater {
                    model: bar.modelData.items || []
                    Rectangle {
                        required property var modelData
                        readonly property string widgetId: typeof modelData === "string" ? modelData : modelData.id
                        width: bar.vertical ? bar.width-8 : widgetId === "spacer" ? 12 : widgetId === "clock" ? 29 : 10
                        height: bar.vertical ? (widgetId === "clock" ? 20 : 10) : bar.height-8
                        radius: 3
                        color: widgetId === "spacer" ? "transparent" : bar.modelData.width === "islands" ? Theme.surface1 : Theme.glowSoft
                        Label { anchors.centerIn: parent; text: parent.widgetId === "clock" ? "21:47" : parent.widgetId === "spacer" ? "" : "•"; color: Theme.accent; font.pixelSize: parent.widgetId === "clock" ? 7 : 10 }
                        ToolTip.visible: hover.hovered
                        ToolTip.text: widgetId
                        HoverHandler { id: hover }
                    }
                }
            }
        }
    }
    Label { anchors.bottom: parent.bottom; anchors.bottomMargin: 37; anchors.horizontalCenter: parent.horizontalCenter; width: parent.width-30; horizontalAlignment: Text.AlignHCenter; text: root.displayName; color: Theme.subtext; font.pixelSize: 9; elide: Text.ElideRight }
}
