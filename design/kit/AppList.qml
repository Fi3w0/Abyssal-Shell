pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

Column {
    id: list
    property int rowHeight: 50
    property int textSize: 15
    property bool icons: true
    property bool descriptions: true
    property bool numbers: false
    property bool invertSelection: false
    property bool flat: false
    property bool edgeMark: false
    property int iconSize: 28
    signal contextRequested(var entry)
    spacing: 3
    Repeater {
        model: Sample.matches
        Controls.Button {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: index === Sample.selected
            readonly property color foreground: current && list.invertSelection ? Theme.current.ink : Theme.current.text
            width: list.width
            height: list.rowHeight
            padding: 12
            hoverEnabled: true
            focusPolicy: Qt.StrongFocus
            Accessible.name: modelData.name
            background: Rectangle {
                radius: Theme.current.radius / 2
                color: row.current && !list.flat ? Theme.current.selected : row.hovered ? Theme.current.raised : "transparent"
                border.width: row.activeFocus ? 2 : 0
                border.color: Theme.current.accent
                Rectangle {
                    visible: row.current && list.edgeMark
                    x: 0
                    y: 12
                    width: 2
                    height: parent.height - 24
                    color: Theme.current.accent
                }
            }
            contentItem: RowLayout {
                spacing: 14
                Label {
                    visible: list.numbers
                    text: "0" + (row.index + 1)
                    color: row.foreground
                    font.pixelSize: 12
                }
                Image {
                    visible: list.icons
                    Layout.preferredWidth: list.iconSize
                    Layout.preferredHeight: list.iconSize
                    source: row.modelData.image
                    sourceSize: Qt.size(64, 64)
                    fillMode: Image.PreserveAspectFit
                }
                ColumnLayout {
                    spacing: 2
                    Layout.fillWidth: true
                    Label {
                        text: row.modelData.name
                        font.pixelSize: list.textSize
                        color: row.foreground
                        Layout.fillWidth: true
                    }
                    Label {
                        visible: list.descriptions
                        text: row.modelData.detail
                        font.pixelSize: 11
                        color: Theme.current.muted
                        Layout.fillWidth: true
                    }
                }
                Label {
                    text: row.current ? "↵" : ""
                    color: row.foreground
                    font.pixelSize: 18
                }
            }
            onClicked: Sample.pick(index)
            TapHandler {
                acceptedButtons: Qt.RightButton
                onTapped: {
                    Sample.pick(row.index);
                    list.contextRequested(row.modelData);
                }
            }
        }
    }
    Label {
        visible: Sample.matches.length === 0
        text: "No matching applications"
        width: list.width
        height: 48
        color: Theme.current.muted
    }
}
