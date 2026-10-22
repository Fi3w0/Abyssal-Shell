import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

RowLayout {
    id: root
    property string value: "classic"
    signal selected(string next)
    spacing: 8
    Repeater {
        model: [{id: "classic", label: "Classic", hint: "Balanced tiling"}, {id: "scroll", label: "Scroll", hint: "Columns in a strip"}, {id: "ocean", label: "Ocean", hint: "An open canvas"}]
        ArchiveButton {
            id: card
            required property var modelData
            objectName: "engine-" + modelData.id
            Layout.fillWidth: true
            Layout.preferredHeight: 104
            checkable: true
            checked: root.value === modelData.id
            Accessible.name: modelData.label
            Accessible.description: modelData.hint
            onClicked: root.selected(modelData.id)
            contentItem: ColumnLayout {
                spacing: 7
                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    Repeater {
                        model: 3
                        Rectangle {
                            required property int index
                            x: card.modelData.id === "classic" ? (index ? parent.width * .52 : 0) : card.modelData.id === "scroll" ? parent.width * index * .34 : parent.width * (.08 + index * .28)
                            y: card.modelData.id === "classic" ? (index === 2 ? 20 : 0) : card.modelData.id === "ocean" ? (index === 1 ? 0 : 13) : 0
                            width: parent.width * (card.modelData.id === "ocean" ? .29 : card.modelData.id === "scroll" ? .3 : .46)
                            height: card.modelData.id === "classic" && index > 0 ? 16 : card.modelData.id === "ocean" ? 22 : 36
                            radius: 3
                            color: card.checked && index === 0 ? Theme.glowSoft : Theme.glass
                            border.color: card.checked ? Theme.glowEdge : Theme.edge
                        }
                    }
                }
                Label { text: card.modelData.label; color: card.checked ? Theme.glow : Theme.text; font.pixelSize: 12; font.bold: true }
                Label { text: card.modelData.hint; color: Theme.subtext; font.pixelSize: 9; Layout.fillWidth: true; elide: Text.ElideRight }
            }
        }
    }
}
