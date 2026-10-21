import QtQuick
import QtQuick.Controls as Controls
import "../services"

Controls.ComboBox {
    id: root
    property var options: []
    property var selectedValue
    signal picked(var value)
    model: options
    textRole: "label"
    currentIndex: options.findIndex(o => o.value === selectedValue)
    implicitWidth: 180
    implicitHeight: Theme.controlHeight
    font { family: Theme.font; pixelSize: Theme.controlFontSize }
    padding: 0
    contentItem: Text {
        text: root.displayText
        leftPadding: 10; rightPadding: 28
        color: root.enabled ? Theme.text : Theme.overlay
        font: root.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    indicator: Icon {
        x: root.width - width - 10
        y: (root.height - height) / 2
        name: "chevron-down"; size: 13; color: Theme.subtext
    }
    background: Rectangle {
        radius: Theme.controlRadius
        color: root.hovered ? Theme.hover : Theme.chip
        border.width: 1
        border.color: root.activeFocus ? Theme.accent : Theme.hairline
    }
    delegate: Controls.ItemDelegate {
        required property int index
        required property var modelData
        width: root.width - 8
        height: Theme.controlHeight
        contentItem: Text {
            text: modelData.label
            color: Theme.text; font: root.font
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: 5
            color: root.highlightedIndex === index ? Theme.accentSoft : "transparent"
        }
    }
    popup: Controls.Popup {
        y: root.height + 4
        width: root.width
        padding: 4
        implicitHeight: Math.min(list.contentHeight + 8, 240)
        contentItem: ListView {
            id: list
            clip: true
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            highlightMoveDuration: 0
            Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
        }
        background: Rectangle {
            color: Theme.glassStrong
            radius: Theme.controlRadius
            border { width: 1; color: Theme.controlEdge }
        }
    }
    onActivated: index => { if (options[index]) picked(options[index].value) }
}
