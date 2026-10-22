import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root
    property color valueColor: Theme.accent
    property real hue: 0
    readonly property real saturation: valueColor.hsvSaturation
    readonly property real brightness: valueColor.hsvValue
    signal edited(color next)
    spacing: 6
    onValueColorChanged: { if (valueColor.hsvHue >= 0) hue = valueColor.hsvHue; }
    Component.onCompleted: { if (valueColor.hsvHue >= 0) hue = valueColor.hsvHue; }
    function update(h, s, v) { hue = h; edited(Qt.hsva(h, s, v, 1)); }
    Rectangle {
        id: plane
        objectName: "colourPlane"
        Layout.fillWidth: true
        Layout.preferredHeight: 112
        color: Qt.hsva(root.hue, 1, 1, 1)
        Rectangle { anchors.fill: parent; gradient: Gradient { orientation: Gradient.Horizontal; GradientStop { position: 0; color: Qt.rgba(1,1,1,1) } GradientStop { position: 1; color: Qt.rgba(1,1,1,0) } } }
        Rectangle { anchors.fill: parent; gradient: Gradient { GradientStop { position: 0; color: Qt.rgba(0,0,0,0) } GradientStop { position: 1; color: Qt.rgba(0,0,0,1) } } }
        Rectangle {
            x: Math.max(0, Math.min(parent.width - width, root.saturation * parent.width - width/2))
            y: Math.max(0, Math.min(parent.height - height, (1-root.brightness) * parent.height - height/2))
            width: 12; height: 12; radius: 6; color: "transparent"; border.width: 2; border.color: Qt.rgba(1,1,1,1)
            Rectangle { anchors.fill: parent; anchors.margins: 2; radius: 4; color: "transparent"; border.color: Qt.rgba(0,0,0,.65) }
        }
        MouseArea {
            anchors.fill: parent
            function choose(mouse) { root.update(root.hue, Math.max(0,Math.min(1,mouse.x/width)), 1-Math.max(0,Math.min(1,mouse.y/height))); }
            onPressed: mouse => choose(mouse)
            onPositionChanged: mouse => { if (pressed) choose(mouse); }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Label { text: "H"; color: Theme.subtext; font.pixelSize: 10 }
        ArchiveSlider {
            objectName: "colourHue"
            Layout.fillWidth: true; from: 0; to: 1; value: root.hue; stepSize: .001
            Accessible.name: "Colour hue"
            onMoved: root.update(value, root.saturation, root.brightness)
            background: Rectangle {
                x: parent.leftPadding; y: (parent.height-height)/2; width: parent.availableWidth; height: 6; radius: 3
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0; color: Qt.hsva(0,1,1,1) }
                    GradientStop { position: 1/6; color: Qt.hsva(1/6,1,1,1) }
                    GradientStop { position: 2/6; color: Qt.hsva(2/6,1,1,1) }
                    GradientStop { position: 3/6; color: Qt.hsva(3/6,1,1,1) }
                    GradientStop { position: 4/6; color: Qt.hsva(4/6,1,1,1) }
                    GradientStop { position: 5/6; color: Qt.hsva(5/6,1,1,1) }
                    GradientStop { position: 1; color: Qt.hsva(1,1,1,1) }
                }
            }
        }
        Label { text: Math.round(root.hue*360) + "°"; color: Theme.subtext; font.pixelSize: 10; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
    }
    Repeater {
        model: [{title:"S", name:"Saturation", value:root.saturation}, {title:"V", name:"Brightness", value:root.brightness}]
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Label { text: modelData.title; color: Theme.subtext; font.pixelSize: 10 }
            ArchiveSlider { objectName: "colour" + modelData.name; Layout.fillWidth: true; from: 0; to: 1; stepSize: .001; value: modelData.value; Accessible.name: "Colour " + modelData.name; onMoved: root.update(root.hue, modelData.title === "S" ? value : root.saturation, modelData.title === "V" ? value : root.brightness) }
            Label { text: Math.round(modelData.value*100) + "%"; color: Theme.subtext; font.pixelSize: 10; Layout.preferredWidth: 34; horizontalAlignment: Text.AlignRight }
        }
    }
    RowLayout {
        Layout.fillWidth: true
        Rectangle { width: 28; height: 28; radius: 5; color: root.valueColor; border.color: Theme.edge }
        ArchiveTextField {
            id: hex
            objectName: "colourHex"
            Layout.fillWidth: true
            Accessible.name: "Hex colour"
            text: root.valueColor.toString()
            maximumLength: 7
            color: activeFocus && !acceptableInput ? Theme.warn : Theme.text
            validator: RegularExpressionValidator { regularExpression: /#[0-9a-fA-F]{6}/ }
            onEditingFinished: { if (acceptableInput) root.edited(Qt.color(text)); }
        }
        Label { text: "RGB " + Math.round(root.valueColor.r*255) + " / " + Math.round(root.valueColor.g*255) + " / " + Math.round(root.valueColor.b*255); color: Theme.subtext; font.pixelSize: 9 }
    }
}
