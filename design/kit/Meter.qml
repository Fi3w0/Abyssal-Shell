import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Item {
    id: meter
    property string label: "Volume"
    property alias value: slider.value
    property int thickness: 3
    property bool ticks: false
    signal moved(real value)
    implicitHeight: 66
    RowLayout {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }
        Label {
            text: meter.label
            Layout.fillWidth: true
            font.pixelSize: 13
        }
        Label {
            text: Math.round(slider.value) + "%"
            color: Theme.current.muted
            font.family: "JetBrains Mono"
            font.pixelSize: 12
        }
    }
    Controls.Slider {
        id: slider
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 35
        from: 0
        to: 100
        stepSize: 1
        focusPolicy: Qt.StrongFocus
        Accessible.name: meter.label
        onMoved: meter.moved(value)
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: meter.thickness
            color: Theme.current.line
            Rectangle {
                width: slider.visualPosition * parent.width
                height: parent.height
                color: Theme.current.accent
            }
            Row {
                visible: meter.ticks
                anchors {
                    top: parent.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: 5
                }
                spacing: (width - 11) / 10
                Repeater {
                    model: 11
                    Rectangle {
                        width: 1
                        height: 4
                        color: Theme.current.line
                    }
                }
            }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: 7
            height: 15
            radius: Theme.current.radius > 2 ? 3 : 0
            color: slider.activeFocus ? Theme.current.text : Theme.current.accent
            border.width: slider.activeFocus ? 1 : 0
            border.color: Theme.current.text
        }
    }
}
